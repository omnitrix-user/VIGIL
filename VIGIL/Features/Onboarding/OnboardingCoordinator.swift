//
//  OnboardingCoordinator.swift
//  VIGIL
//

import Foundation
import Observation
import SwiftData
import SwiftUI

enum Weakness: String, CaseIterable, Codable, Hashable {
    case procrastination = "Procrastination"
    case distraction = "Distraction"
    case laziness = "Laziness"
    case anxiety = "Anxiety"
    case poorSleep = "Poor Sleep"
    case addiction = "Addiction"
    case lackOfFocus = "Lack Of Focus"
    case other = "Other"
}

struct WeaknessCascadeDraft: Codable, Hashable {
    var source: String = ""
    var frequency: String = "Daily"
    var duration: Double = 60
    var verdict: VerdictOption = .trackOnly
    var cap: Double = 60
}

struct OnboardingStatePayload: Codable {
    var step: OnboardingStep
    var selectedWeaknesses: [Weakness]
    var weaknessCascade: WeaknessCascadeCoordinator
}

struct SuggestedGoal: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var category: StatCategory
    var goalType: GoalType
    var targetValue: Double
    var unit: String
    var isCapGoal: Bool
    var active: Bool = true
}

@MainActor
@Observable
final class OnboardingCoordinator {
    var step: OnboardingStep = .scan
    var queryIndex = 1
    let totalQueries = 40
    var abandonWarning = false

    var username = ""
    var age = 21
    var designationType = "Prefer Not To Disclose"
    var lifeStatus = "Student"
    var selectedWeaknesses: Set<Weakness> = []
    var weaknessCascade = WeaknessCascadeCoordinator()
    var declaredDistractions: [DeclaredDistraction] = []

    var fieldOfFocus = ""
    var specificObjective = ""
    var targetCompletion = "6mo"
    var currentDailyInvestment = 2.0
    var requiredDailyInvestment = 4.0

    var physicalState = "Average"
    var currentMass = 70.0
    var targetMass = 75.0
    var activityLevel = "Moderate"
    var targetTrainingFrequency = 4.0
    var trainingType: Set<String> = []

    var currentBedTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now) ?? .now
    var currentWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    var targetBedTime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: .now) ?? .now
    var targetWakeTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: .now) ?? .now
    var sleepQuality = "Good"
    var mindfulnessPractice = "Occasional"
    var recoveryHobbies: Set<String> = []

    var profileFragment = ""
    var suggestedGoals: [SuggestedGoal] = []
    var signatureHash = ""

    func advance() {
        guard let idx = OnboardingStep.allCases.firstIndex(of: step),
              idx < OnboardingStep.allCases.count - 1 else { return }
        step = OnboardingStep.allCases[idx + 1]
        queryIndex = min(totalQueries, queryIndex + 1)
        if step == .dailyGoalConfirmation { buildSuggestedGoals() }
    }

    func registerAbandonAttempt() {
        abandonWarning = true
    }

    var sortedSelectedWeaknesses: [Weakness] { Weakness.allCases.filter { selectedWeaknesses.contains($0) } }

    func toggleWeakness(_ weakness: Weakness) {
        if selectedWeaknesses.contains(weakness) {
            selectedWeaknesses.remove(weakness)
        } else {
            selectedWeaknesses.insert(weakness)
        }
    }

    func beginWeaknessCascade() {
        weaknessCascade.start(with: sortedSelectedWeaknesses)
    }

    func canAdvanceCurrentPhase() -> Bool {
        guard let inProgress = weaknessCascade.inProgress else { return false }
        switch weaknessCascade.phase {
        case .source:
            return !inProgress.source
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        case .frequency, .duration, .verdict, .cap:
            return true
        }
    }

    func advanceWeaknessCascade() -> Bool {
        var updated = weaknessCascade
        let isComplete = updated.advance()
        weaknessCascade = updated

        if isComplete {
            declaredDistractions = weaknessCascade.completed
        }
        return isComplete
    }

    func goToPreviousWeaknessStep() {
        var updated = weaknessCascade
        updated.back()
        weaknessCascade = updated
    }

    func updateCurrentWeakness(_ mutate: (inout PartialDeclaredDistraction) -> Void) {
        guard var current = weaknessCascade.inProgress else { return }
        mutate(&current)
        var updated = weaknessCascade
        updated.update(current)
        weaknessCascade = updated
    }

    func restore(from payload: OnboardingStatePayload) {
        step = payload.step
        selectedWeaknesses = Set(payload.selectedWeaknesses)
        weaknessCascade = payload.weaknessCascade
        declaredDistractions = payload.weaknessCascade.completed
    }

    func payload() -> OnboardingStatePayload {
        OnboardingStatePayload(
            step: step,
            selectedWeaknesses: Array(selectedWeaknesses),
            weaknessCascade: weaknessCascade
        )
    }

    func encodePayload() -> String {
        guard let data = try? JSONEncoder().encode(payload()),
              let raw = String(data: data, encoding: .utf8) else { return "{}" }
        return raw
    }

    func decodePayload(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(OnboardingStatePayload.self, from: data) else { return }
        restore(from: payload)
    }

    func complete(modelContext: ModelContext) throws -> Player {
        let player = Player(
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            signatureHash: signatureHash,
            wakeTime: targetWakeTime,
            sleepTime: targetBedTime,
            focusHoursStart: targetWakeTime,
            focusHoursEnd: targetBedTime,
            restHoursStart: targetBedTime,
            restHoursEnd: targetWakeTime,
            dailyResetTime: Calendar.current.date(byAdding: .minute, value: -30, to: targetWakeTime) ?? targetWakeTime,
            notificationsVerdict: true,
            notificationsQuests: true,
            notificationsViolations: true,
            notificationsMorningBrief: true,
            isLightModeEnabled: false,
            friendCode: Self.generateFriendCode(),
            declaredDistractions: declaredDistractions
        )
        for g in suggestedGoals where g.active {
            let goal = Goal(name: g.name, category: g.category, goalType: g.goalType, targetValue: g.targetValue, unit: g.unit, isCapGoal: g.isCapGoal, xpPerUnit: 2, xpPenaltyPerUnit: g.isCapGoal ? 2 : 0, isActive: true, colorHex: "#6C63FF", icon: "scope", startDate: Date(), player: player)
            player.goals.append(goal)
            modelContext.insert(goal)
        }
        modelContext.insert(player)
        try modelContext.save()
        return player
    }

    private func buildSuggestedGoals() {
        if !suggestedGoals.isEmpty { return }
        suggestedGoals = [
            SuggestedGoal(name: "DEEP WORK", category: .intelligence, goalType: .duration, targetValue: requiredDailyInvestment * 60, unit: "minutes", isCapGoal: false),
            SuggestedGoal(name: "TRAINING", category: .strength, goalType: .count, targetValue: max(1, targetTrainingFrequency), unit: "sessions", isCapGoal: false),
            SuggestedGoal(name: "SLEEP CONSISTENCY", category: .vitality, goalType: .boolean, targetValue: 1, unit: "complete", isCapGoal: false),
        ]
        if declaredDistractions.contains(where: { $0.verdict == .limit }) {
            suggestedGoals.append(
                SuggestedGoal(name: "DISTRACTION CAP", category: .discipline, goalType: .duration, targetValue: declaredDistractions.first(where: { $0.verdict == .limit })?.capValue ?? 60, unit: "minutes", isCapGoal: true)
            )
        }
    }

    private static func generateFriendCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement() ?? "X" })
    }
}

struct OnboardingHostView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressRows: [OnboardingProgress]
    @State private var coordinator = OnboardingCoordinator()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.bg.primary.ignoresSafeArea()
            content
            if coordinator.abandonWarning {
                Text("YOU ATTEMPTED TO ABANDON EVALUATION. THE SYSTEM HAS NOTED THIS HESITATION. CONTINUE.")
                    .font(.vigil.system)
                    .foregroundStyle(Color.status.warning)
                    .padding()
                    .background(Color.bg.secondary)
                    .overlay(Rectangle().stroke(Color.status.warning, lineWidth: 1))
                    .padding()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { coordinator.abandonWarning = false }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { coordinator.registerAbandonAttempt() }
        .task {
            if let existing = progressRows.first {
                coordinator.decodePayload(existing.payloadJSON)
            } else {
                let row = OnboardingProgress()
                modelContext.insert(row)
                try? modelContext.save()
            }
        }
        .onChange(of: coordinator.step) { _, _ in persistProgress() }
        .onChange(of: coordinator.selectedWeaknesses) { _, _ in persistProgress() }
        .onChange(of: coordinator.weaknessCascade.currentIndex) { _, _ in persistProgress() }
        .onChange(of: coordinator.weaknessCascade.phase) { _, _ in persistProgress() }
        .onChange(of: coordinator.weaknessCascade.inProgress) { _, _ in persistProgress() }
        .onDisappear { persistProgress() }
    }

    private func persistProgress() {
        let row = progressRows.first ?? OnboardingProgress()
        if progressRows.isEmpty { modelContext.insert(row) }
        row.currentStep = coordinator.step.rawValue
        row.currentQueryIndex = coordinator.queryIndex
        row.totalQueries = coordinator.totalQueries
        row.payloadJSON = coordinator.encodePayload()
        row.updatedAt = Date()
        try? modelContext.save()
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.step {
        case .scan:
            ScanView { coordinator.advance() }
        case .identity:
            InterrogationView(coordinator: coordinator) { coordinator.advance() }
        case .weaknessCascade:
            GoalSetupView(coordinator: coordinator) {
                coordinator.advance()
            }
        case .profileFragmentOne, .profileFragmentTwo, .profileFragmentThree, .profileFragmentFour:
            FragmentView(step: coordinator.step) { coordinator.advance() }
        case .intelligence:
            IntelligenceView(coordinator: coordinator) { coordinator.advance() }
        case .strength:
            StrengthView(coordinator: coordinator) { coordinator.advance() }
        case .vitality:
            VitalityView(coordinator: coordinator) { coordinator.advance() }
        case .dailyGoalConfirmation:
            DailyGoalsConfirmationView(coordinator: coordinator) { coordinator.advance() }
        case .permissions:
            PermissionsView { coordinator.advance() }
        case .contract:
            ContractView(goalsText: coordinator.suggestedGoals.filter(\.active).map(\.name)) { hash in
                coordinator.signatureHash = hash
                if let player = try? coordinator.complete(modelContext: modelContext) {
                    QuestTriggerService.shared.markOnboardingCompleted()
                    Task { await QuestTriggerService.shared.evaluateTriggers(modelContext: modelContext) }
                    onComplete()
                }
            }
        }
    }
}
