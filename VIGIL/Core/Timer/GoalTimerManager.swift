//
//  GoalTimerManager.swift
//  VIGIL
//

import ActivityKit
import BackgroundTasks
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class GoalTimerManager {
    static let shared = GoalTimerManager()

    private(set) var activeGoalId: UUID?
    private(set) var elapsedSeconds = 0
    private(set) var isRunning = false

    private var accumulatedBasisSeconds = 0
    private var runningSegmentStartDate: Date?
    private var tick: Timer?

    private let defaultsKey = "vigil.goalTimer.state.v5"
    static let backgroundTaskIdentifier = "com.vigil.goalTimerRefresh"

    @available(iOS 16.2, *)
    private var liveActivityToken: Activity<VigilTimerAttributes>?

    private struct CapHUD: Sendable {
        let loggedToday: Double
        let targetMinutes: Double
        let isCap: Bool
    }

    private var capHUD: CapHUD?

    private init() {
        loadFromDefaults()
        recomputeElapsed()
    }

    // MARK: — HUD for cap warnings

    func updateCapHUD(loggedToday: Double, targetMinutes: Double, isCapGoal: Bool) {
        capHUD = CapHUD(loggedToday: loggedToday, targetMinutes: targetMinutes, isCap: isCapGoal)
    }

    func clearCapHUD() {
        capHUD = nil
    }

    func peekActiveGoalId() -> UUID? {
        activeGoalId
    }

    func hasForeignActiveTimer(comparedTo goalId: UUID) -> Bool {
        guard let aid = activeGoalId else { return false }
        return aid != goalId
    }

    /// Duration session loaded but timer not accumulating (paused).
    var isPausedSession: Bool {
        activeGoalId != nil && !isRunning
    }

    // MARK: — Lifecycle hooks

    func registerBackgroundProcessing() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundTaskIdentifier, using: nil) { task in
            Task { @MainActor in
                self.tickWallClockBaseline()
                self.persist()
                await self.liveActivitySynchronize()
                task.setTaskCompleted(success: true)
            }
        }
    }

    func scheduleBackgroundPulse() {
        let request = BGProcessingTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 180)
        try? BGTaskScheduler.shared.submit(request)
    }

    func sceneBecameActive() {
        tickWallClockBaseline()
        startSecondTicker()
        Task { await liveActivitySynchronize() }
    }

    func sceneWillResignActive() {
        stopSecondTicker()
        tickWallClockBaseline()
        persist()
        scheduleBackgroundPulse()
    }

    // MARK: — Controls

    func startTimer(for goal: Goal) throws {
        guard goal.goalType == GoalType.duration else {
            throw GoalTimerManagerError.requiresDurationGoal
        }

        if let current = activeGoalId, current == goal.id {
            if !isRunning {
                resumeAfterPause()
                Task { await beginLive(goal: goal) }
                startSecondTicker()
            }
            return
        }

        if let current = activeGoalId, current != goal.id {
            throw GoalTimerManagerError.anotherSessionActive
        }

        activeGoalId = goal.id
        accumulatedBasisSeconds = 0
        runningSegmentStartDate = Date()
        isRunning = true
        recomputeElapsed()
        persist()
        Task { await beginLive(goal: goal) }
        startSecondTicker()
    }

    func pauseTimer() {
        guard activeGoalId != nil else { return }
        stopSecondTicker()
        foldSegmentIntoAccumulator()
        isRunning = false
        persist()
        Task { await liveActivitySynchronize() }
    }

    func resumeAfterPause() {
        guard activeGoalId != nil else { return }
        guard !isRunning else { return }
        runningSegmentStartDate = Date()
        isRunning = true
        persist()
        Task { await liveActivitySynchronize() }
    }

    /// `finalizeCredits` — when true logs minutes + XP via SwiftData save.
    func stopTimer(goal: Goal, modelContext: ModelContext, finalizeCredits: Bool) throws -> CompletedSession {
        guard let gid = activeGoalId, gid == goal.id else {
            throw GoalTimerManagerError.noActiveSession
        }
        guard goal.goalType == GoalType.duration else {
            throw GoalTimerManagerError.requiresDurationGoal
        }

        stopSecondTicker()
        if isRunning {
            foldSegmentIntoAccumulator()
        }
        isRunning = false
        recomputeElapsed()

        let minutesElapsed = Double(elapsedSeconds) / 60

        if !finalizeCredits {
            let session = CompletedSession(
                goalId: goal.id,
                durationMinutes: minutesElapsed,
                valueLogged: 0,
                xpAwarded: 0,
                wasCompleted: false
            )
            resetLocalSession()
            persist()
            Task { await teardownLiveActivity() }
            return session
        }

        if minutesElapsed <= 0 {
            let session = CompletedSession(goalId: goal.id, durationMinutes: 0, valueLogged: 0, xpAwarded: 0, wasCompleted: true)
            resetLocalSession()
            persist()
            Task { await teardownLiveActivity() }
            return session
        }

        let dayProgress = GoalDashboardFormatting.loggedValueToday(for: goal)
        let award = RewardMath.duration(goal: goal, sessionMinutes: minutesElapsed, loggedTodayBefore: dayProgress)

        let entry = GoalCompletion(
            loggedAt: Date(),
            value: award.loggedUnits,
            goal: goal,
            dayLog: nil
        )
        modelContext.insert(entry)

        if let player = goal.player, award.netXP != 0 {
            StatXP.apply(delta: award.netXP, category: goal.category, to: player)
        }

        try modelContext.save()
        persist()
        let session = CompletedSession(
            goalId: goal.id,
            durationMinutes: minutesElapsed,
            valueLogged: award.loggedUnits,
            xpAwarded: award.netXP,
            wasCompleted: true
        )
        resetLocalSession()
        Task { await teardownLiveActivity() }
        return session
    }

    func markBoolean(goal: Goal, modelContext: ModelContext, complete: Bool) throws -> CompletedSession {
        guard goal.goalType == GoalType.boolean else {
            throw GoalTimerManagerError.requiresBooleanGoal
        }
        guard let player = goal.player else {
            throw GoalTimerManagerError.missingPlayer
        }

        guard complete else {
            return CompletedSession(goalId: goal.id, durationMinutes: 0, valueLogged: 0, xpAwarded: 0, wasCompleted: false)
        }

        let threshold = max(goal.targetValue, 1)
        let xp = goal.xpPerUnit

        let entry = GoalCompletion(
            loggedAt: Date(),
            value: threshold,
            goal: goal,
            dayLog: nil
        )
        modelContext.insert(entry)
        StatXP.apply(delta: xp, category: goal.category, to: player)
        try modelContext.save()

        return CompletedSession(goalId: goal.id, durationMinutes: 0, valueLogged: threshold, xpAwarded: xp, wasCompleted: true)
    }

    func logCountSession(goal: Goal, units: Double, modelContext: ModelContext) throws -> CompletedSession {
        guard goal.goalType == GoalType.count else {
            throw GoalTimerManagerError.requiresCountGoal
        }
        guard let player = goal.player else {
            throw GoalTimerManagerError.missingPlayer
        }
        guard units > 0 else {
            throw GoalTimerManagerError.invalidLoggedUnits
        }

        let xp = Int((units * Double(goal.xpPerUnit)).rounded())
        let entry = GoalCompletion(
            loggedAt: Date(),
            value: units,
            goal: goal,
            dayLog: nil
        )
        modelContext.insert(entry)
        if xp != 0 {
            StatXP.apply(delta: xp, category: goal.category, to: player)
        }
        try modelContext.save()

        return CompletedSession(
            goalId: goal.id,
            durationMinutes: 0,
            valueLogged: units,
            xpAwarded: max(0, xp),
            wasCompleted: true
        )
    }

    // MARK: — Live Activity intent bridge

    func handleLiveActivityStopIntent() async {
        guard let context = VIGILPersistence.makeContext(),
              let gid = activeGoalId else {
            resetLocalSession()
            await teardownLiveActivity()
            return
        }

        var fetch = FetchDescriptor<Goal>(predicate: #Predicate { $0.id == gid })
        fetch.fetchLimit = 1

        guard let goal = try? context.fetch(fetch).first else {
            resetLocalSession()
            await teardownLiveActivity()
            return
        }

        do {
            _ = try stopTimer(goal: goal, modelContext: context, finalizeCredits: true)
        } catch {
            resetLocalSession()
            await teardownLiveActivity()
        }
    }

    // MARK: — Time core

    private func recomputeElapsed() {
        if let start = runningSegmentStartDate, isRunning {
            let delta = max(0, Int(Date().timeIntervalSince(start).rounded(.towardZero)))
            elapsedSeconds = accumulatedBasisSeconds + delta
        } else {
            elapsedSeconds = accumulatedBasisSeconds
        }
    }

    private func foldSegmentIntoAccumulator() {
        guard let start = runningSegmentStartDate else { return }
        accumulatedBasisSeconds += max(0, Int(Date().timeIntervalSince(start).rounded(.towardZero)))
        runningSegmentStartDate = nil
        elapsedSeconds = accumulatedBasisSeconds
    }

    func tickWallClockBaseline() {
        recomputeElapsed()
    }

    private func startSecondTicker() {
        tick?.invalidate()
        guard activeGoalId != nil else { return }
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.recomputeElapsed()
                self.persist()
                await self.liveActivitySynchronize()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        tick = t
    }

    private func stopSecondTicker() {
        tick?.invalidate()
        tick = nil
    }

    private func resetLocalSession() {
        activeGoalId = nil
        accumulatedBasisSeconds = 0
        runningSegmentStartDate = nil
        isRunning = false
        elapsedSeconds = 0
        capHUD = nil
        tick?.invalidate()
        tick = nil
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    // MARK: — Persistence

    private struct Snapshot: Codable {
        let goalID: UUID?
        let basis: Int
        let segmentEpoch: TimeInterval?
        let runningFlag: Bool
    }

    private func persist() {
        let blob = Snapshot(
            goalID: activeGoalId,
            basis: accumulatedBasisSeconds,
            segmentEpoch: runningSegmentStartDate?.timeIntervalSince1970,
            runningFlag: isRunning
        )
        if let encoded = try? JSONEncoder().encode(blob) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }

    private func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data),
              let gid = snap.goalID else { return }
        activeGoalId = gid
        accumulatedBasisSeconds = max(0, snap.basis)
        isRunning = snap.runningFlag
        if snap.runningFlag, let epoch = snap.segmentEpoch {
            runningSegmentStartDate = Date(timeIntervalSince1970: epoch)
        }
        recomputeElapsed()
        if activeGoalId != nil {
            startSecondTicker()
        }
    }

    private func capLine() -> String {
        guard let hud = capHUD, hud.isCap, hud.targetMinutes > 0 else { return "" }
        let projected = hud.loggedToday + Double(elapsedSeconds) / 60
        let warn = hud.targetMinutes * 0.85
        if projected >= warn { return "APPROACHING CAP" }
        return ""
    }

    // MARK: — ActivityKit

    private func beginLive(goal: Goal) async {
        if #available(iOS 16.2, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            await teardownLiveActivityInternal()
            let attrs = VigilTimerAttributes(goalName: goal.name, goalId: goal.id)
            let state = VigilTimerAttributes.ContentState(
                elapsedSeconds: elapsedSeconds,
                isPaused: !isRunning,
                capWarningLine: capLine()
            )
            liveActivityToken = try? Activity.request(
                attributes: attrs,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        }
    }

    private func liveActivitySynchronize() async {
        guard #available(iOS 16.2, *) else { return }
        guard let activity = liveActivityToken else { return }
        let blob = VigilTimerAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            isPaused: !isRunning,
            capWarningLine: capLine()
        )
        await activity.update(ActivityContent(state: blob, staleDate: Date().addingTimeInterval(125)))
    }

    private func teardownLiveActivity() async {
        if #available(iOS 16.2, *) {
            await teardownLiveActivityInternal()
        }
    }

    @available(iOS 16.2, *)
    private func teardownLiveActivityInternal() async {
        if let activity = liveActivityToken {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        liveActivityToken = nil
    }
}

// MARK: — Reward helpers

private enum RewardMath {
    struct DurationAward {
        let loggedUnits: Double
        let netXP: Int
    }

    static func duration(goal: Goal, sessionMinutes: Double, loggedTodayBefore: Double) -> DurationAward {
        let loggedUnits = sessionMinutes

        if !goal.isCapGoal {
            let xp = Int((sessionMinutes * Double(goal.xpPerUnit)).rounded())
            return DurationAward(loggedUnits: loggedUnits, netXP: max(0, xp))
        }

        let capTotal = goal.targetValue
        let room = max(0, capTotal - loggedTodayBefore)
        let minutesCreditedTowardCap = min(sessionMinutes, room)
        let over = max(0, sessionMinutes - room)

        let earnXP = Int((minutesCreditedTowardCap * Double(goal.xpPerUnit)).rounded())
        let bleedXP = Int((over * Double(goal.xpPenaltyPerUnit)).rounded())
        let net = max(0, earnXP - bleedXP)

        return DurationAward(loggedUnits: loggedUnits, netXP: net)
    }
}

private enum StatXP {
    static func apply(delta: Int, category: StatCategory, to player: Player) {
        guard delta != 0 else { return }
        switch category {
        case .intellect:
            var blk = player.intellect
            blk.currentXP = max(0, blk.currentXP + delta)
            if delta > 0 { blk.totalXP += delta }
            player.intellect = blk
        case .strength:
            var blk = player.strength
            blk.currentXP = max(0, blk.currentXP + delta)
            if delta > 0 { blk.totalXP += delta }
            player.strength = blk
        case .spirit:
            var blk = player.spirit
            blk.currentXP = max(0, blk.currentXP + delta)
            if delta > 0 { blk.totalXP += delta }
            player.spirit = blk
        case .discipline:
            var blk = player.discipline
            blk.currentXP = max(0, blk.currentXP + delta)
            if delta > 0 { blk.totalXP += delta }
            player.discipline = blk
        }
    }
}

enum GoalTimerManagerError: LocalizedError {
    case anotherSessionActive
    case requiresDurationGoal
    case requiresBooleanGoal
    case requiresCountGoal
    case missingPlayer
    case noActiveSession
    case invalidLoggedUnits

    var errorDescription: String? {
        switch self {
        case .anotherSessionActive: return "Another session is active."
        case .requiresDurationGoal: return "Timer supports duration objectives only."
        case .requiresBooleanGoal: return "Objective is not boolean."
        case .requiresCountGoal: return "Objective is not a count objective."
        case .missingPlayer: return "No Player bound to objective."
        case .noActiveSession: return "Timer already cleared."
        case .invalidLoggedUnits: return "Nothing to log."
        }
    }
}
