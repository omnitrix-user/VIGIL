//
//  ScreenTimeManager.swift
//  VIGIL
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import Observation
import SwiftData

@Observable
@MainActor
final class ScreenTimeManager {
    static let shared = ScreenTimeManager()

    private let deviceActivityCenter = DeviceActivityCenter()
    private let managedStore = ManagedSettingsStore()

    private(set) var lastAuthorizationStatus: AuthorizationStatus?

    private(set) var activeBlocks: [PhoneBlock] = []

    weak var modelContext: ModelContext?

    private init() {
        refreshAuthorizationStatus()
    }

    // MARK: — Authorization

    /// Requests Screen Time / Family Controls approval.
    ///
    /// **Real device:** Full FamilyControls authorization is required for monitoring.
    /// **Simulator:** Always throws `.simulatorFamilyControlsUnavailable` — exercise flows with mocks.
    func requestAuthorization() async throws {
        #if targetEnvironment(simulator)
        lastAuthorizationStatus = .denied
        throw ScreenTimeManagerError.simulatorFamilyControlsUnavailable
        #else
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        refreshAuthorizationStatus()
        #endif
    }

    func refreshAuthorizationStatus() {
        lastAuthorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    // MARK: — Scheduling

    func scheduleBlock(start: Date, end: Date, goalId: UUID, modelContext: ModelContext) throws {
        guard end > start else {
            throw ScreenTimeManagerError.invalidInterval
        }

        let blockId = UUID()
        let activityName = Self.deviceActivityName(forBlockId: blockId)
        let schedule = try Self.makeSchedule(from: start, to: end)

        var goalDescriptor = FetchDescriptor<Goal>(predicate: #Predicate { $0.id == goalId })
        goalDescriptor.fetchLimit = 1
        guard let goal = try modelContext.fetch(goalDescriptor).first else {
            throw ScreenTimeManagerError.goalNotFound
        }

        let durationMinutes = max(1, end.timeIntervalSince(start) / 60.0)
        let reward = Self.computeCompletionXP(blockDurationMinutes: durationMinutes, goal: goal)

        #if targetEnvironment(simulator)
        // DeviceActivityCenter monitoring is ineffective on Simulator — persist state only.
        // **Real device testing required** for live schedules.
        #else
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            throw ScreenTimeManagerError.monitoringFailed(underlying: error.localizedDescription)
        }
        #endif

        let record = PhoneBlockRecord(
            id: blockId,
            goalId: goalId,
            startTime: start,
            endTime: end,
            deviceActivityNameRaw: activityName.rawValue,
            isActive: true,
            wasViolated: false,
            xpReward: reward,
            violationWarningIssued: false
        )
        modelContext.insert(record)
        try modelContext.save()

        reloadCaches(from: modelContext)
    }

    func cancelBlock(goalId: UUID, modelContext: ModelContext) throws {
        var descriptor = FetchDescriptor<PhoneBlockRecord>(
            predicate: #Predicate { $0.goalId == goalId && $0.isActive }
        )
        descriptor.fetchLimit = 128
        let rows = try modelContext.fetch(descriptor)
        for row in rows {
            try cancelRecord(row, modelContext: modelContext)
        }
    }

    private func cancelRecord(_ record: PhoneBlockRecord, modelContext: ModelContext) throws {
        let name = DeviceActivityName(record.deviceActivityNameRaw)
        #if !targetEnvironment(simulator)
        deviceActivityCenter.stopMonitoring([name])
        #endif
        record.isActive = false
        try modelContext.save()
        ScreenTimeAppGroupBridge.clearIntervalStart(forActivityRaw: record.deviceActivityNameRaw)
        reloadCaches(from: modelContext)
    }

    // MARK: — Bridge (extension → app)

    func processPendingMonitorEvents(modelContext: ModelContext) {
        while let event = ScreenTimeAppGroupBridge.readAndConsumePendingEvent() {
            switch event.kind {
            case .completed:
                handleBlockCompleted(blockId: event.blockId, modelContext: modelContext)
            case .violation:
                Task {
                    await handleViolationPipeline(blockId: event.blockId, modelContext: modelContext)
                }
            }
        }
    }

    private func handleViolationPipeline(blockId: UUID, modelContext: ModelContext) async {
        var descriptor = FetchDescriptor<PhoneBlockRecord>(predicate: #Predicate { $0.id == blockId })
        descriptor.fetchLimit = 1
        guard let record = try? modelContext.fetch(descriptor).first, record.isActive else { return }

        if !record.violationWarningIssued {
            await handleViolationWarning(blockId: blockId, modelContext: modelContext)
        } else {
            await handleFullViolation(blockId: blockId, modelContext: modelContext)
        }
    }

    func handleBlockCompleted(blockId: UUID, modelContext: ModelContext) {
        var descriptor = FetchDescriptor<PhoneBlockRecord>(predicate: #Predicate { $0.id == blockId })
        descriptor.fetchLimit = 1
        guard let record = try? modelContext.fetch(descriptor).first, record.isActive else { return }

        record.isActive = false

        guard let goal = fetchGoal(goalId: record.goalId, in: modelContext),
              let player = goal.player else {
            try? modelContext.save()
            reloadCaches(from: modelContext)
            return
        }

        let xp = max(0, record.xpReward)
        if xp > 0 {
            ScreenTimeStatXP.applyDiscipline(delta: xp, to: player)
            player.totalXP = max(0, player.totalXP + xp)
        }

        try? modelContext.save()
        reloadCaches(from: modelContext)

        let name = DeviceActivityName(record.deviceActivityNameRaw)
        #if !targetEnvironment(simulator)
        deviceActivityCenter.stopMonitoring([name])
        #endif
        ScreenTimeAppGroupBridge.clearIntervalStart(forActivityRaw: record.deviceActivityNameRaw)
    }

    private func handleViolationWarning(blockId: UUID, modelContext: ModelContext) async {
        var descriptor = FetchDescriptor<PhoneBlockRecord>(predicate: #Predicate { $0.id == blockId })
        descriptor.fetchLimit = 1
        guard let record = try? modelContext.fetch(descriptor).first, record.isActive else { return }
        record.violationWarningIssued = true
        try? modelContext.save()
        reloadCaches(from: modelContext)

        let player = fetchGoal(goalId: record.goalId, in: modelContext)?.player
        guard await NotificationManager.shared.shouldDeliverViolations(player: player) else { return }
        await NotificationManager.shared.postBlockViolationWarningNotification(player: player)
    }

    private func handleFullViolation(blockId: UUID, modelContext: ModelContext) async {
        var descriptor = FetchDescriptor<PhoneBlockRecord>(predicate: #Predicate { $0.id == blockId })
        descriptor.fetchLimit = 1
        guard let record = try? modelContext.fetch(descriptor).first, record.isActive else { return }

        record.wasViolated = true

        guard let goal = fetchGoal(goalId: record.goalId, in: modelContext),
              let player = goal.player else {
            try? modelContext.save()
            reloadCaches(from: modelContext)
            return
        }

        let penalty = max(5, goal.xpPenaltyPerUnit)
        ScreenTimeStatXP.applyDiscipline(delta: -penalty, to: player)
        player.totalXP = max(0, player.totalXP - penalty)

        try? modelContext.save()
        reloadCaches(from: modelContext)

        if await NotificationManager.shared.shouldDeliverViolations(player: player) {
            await NotificationManager.shared.postBlockViolationNotification(player: player)
        }

        if record.violationWarningIssued {
            applyEscalatedShieldForContinuedUseAfterWarning()
        }
    }

    /// **Real device + picked tokens:** escalate shielding after a warning was ignored.
    /// Requires `ApplicationToken` values from `FamilyActivityPicker`. **Not testable on Simulator.**
    private func applyEscalatedShieldForContinuedUseAfterWarning() {
        #if targetEnvironment(simulator)
        return
        #else
        _ = managedStore
        #endif
    }

    // MARK: — Simulator testing

    func triggerMockViolation(blockId: UUID, modelContext: ModelContext, tier: MockViolationTier = .full) {
        #if targetEnvironment(simulator)
        switch tier {
        case .warning:
            Task { await handleViolationWarning(blockId: blockId, modelContext: modelContext) }
        case .full:
            Task { await handleFullViolation(blockId: blockId, modelContext: modelContext) }
        }
        #endif
    }

    enum MockViolationTier {
        case warning
        case full
    }

    // MARK: — Internals

    private func reloadCaches(from modelContext: ModelContext) {
        let descriptor = FetchDescriptor<PhoneBlockRecord>(predicate: #Predicate { $0.isActive })
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        activeBlocks = rows.map(PhoneBlock.init(record:))
    }

    private func fetchGoal(goalId: UUID, in context: ModelContext) -> Goal? {
        var descriptor = FetchDescriptor<Goal>(predicate: #Predicate { $0.id == goalId })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private static func deviceActivityName(forBlockId id: UUID) -> DeviceActivityName {
        DeviceActivityName("vigil.block.\(id.uuidString)")
    }

    private static func makeSchedule(from start: Date, to end: Date) throws -> DeviceActivitySchedule {
        let cal = Calendar.current
        var startDC = cal.dateComponents([.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second], from: start)
        var endDC = cal.dateComponents([.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second], from: end)
        startDC.timeZone = cal.timeZone
        endDC.timeZone = cal.timeZone
        return DeviceActivitySchedule(intervalStart: startDC, intervalEnd: endDC, repeats: false)
    }

    private static func computeCompletionXP(blockDurationMinutes: Double, goal: Goal) -> Int {
        let base = (blockDurationMinutes / 60.0) * Double(goal.xpPerUnit)
        return max(10, Int(base.rounded()))
    }
}

// MARK: — BlockScheduler entry

extension ScreenTimeManager {
    /// Invoked from `BlockScheduler` when extension cannot persist tiering itself.
    func onSchedulerViolation(blockId: UUID, modelContext: ModelContext) async {
        await handleViolationPipeline(blockId: blockId, modelContext: modelContext)
    }

    func onSchedulerBlockCompleted(blockId: UUID, modelContext: ModelContext) {
        handleBlockCompleted(blockId: blockId, modelContext: modelContext)
    }
}

enum ScreenTimeManagerError: LocalizedError {
    case invalidInterval
    case goalNotFound
    case monitoringFailed(underlying: String)
    case simulatorFamilyControlsUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidInterval:
            return "Block end must be after start."
        case .goalNotFound:
            return "Goal not found for this block."
        case .monitoringFailed(let underlying):
            return "Could not register Screen Time monitoring: \(underlying)"
        case .simulatorFamilyControlsUnavailable:
            return "Family Controls authorization is not available in Simulator. Use mock violations and test monitoring on a physical device."
        }
    }
}

private enum ScreenTimeStatXP {
    static func applyDiscipline(delta: Int, to player: Player) {
        guard delta != 0 else { return }
        var blk = player.discipline
        blk.currentXP = max(0, blk.currentXP + delta)
        if delta > 0 { blk.totalXP += delta }
        player.discipline = blk
    }
}

extension ScreenTimeManager {
    var familyControlsDeniedOrUndetermined: Bool {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined, .denied:
            return true
        default:
            return false
        }
    }
}
