//
//  OnboardingCoordinator.swift
//  VIGIL
//

import Foundation
import Observation
import SwiftData
import SwiftUI

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
    var selectedWeaknesses: Set<String> = []
    var weaknessSource = ""
    var weaknessFrequency = "Daily"
    var weaknessDuration = 60.0
    var weaknessVerdict: VerdictOption = .trackOnly
    var weaknessCap = 60.0

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
            friendCode: Self.generateFriendCode()
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
        if weaknessVerdict == .limit {
            suggestedGoals.append(
                SuggestedGoal(name: "DISTRACTION CAP", category: .discipline, goalType: .duration, targetValue: weaknessCap, unit: "minutes", isCapGoal: true)
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
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.step {
        case .scan:
            ScanView { coordinator.advance() }
        case .identity:
            InterrogationView(coordinator: coordinator) { coordinator.advance() }
        case .weaknessCascade:
            GoalSetupView(coordinator: coordinator) { coordinator.advance() }
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
                    Task { await QuestTriggerService.shared.issueImmediateWelcomeQuest(for: player, modelContext: modelContext) }
                    onComplete()
                }
            }
        }
    }
}
