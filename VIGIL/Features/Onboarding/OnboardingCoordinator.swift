//
//  OnboardingCoordinator.swift
//  VIGIL
//

import Foundation
import Observation
import SwiftData
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case scan
    case q1Name
    case q2Goal
    case q3Weakness
    case q4Serious
    case q5Schedule
    case q6Goals
    case goalSetup
    case contract
    case permissions
}

struct GoalDraft: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var category: StatCategory
    var goalType: GoalType
    var targetValue: Double
    var unit: String
    var isCapGoal: Bool
    var xpPerUnit: Int
    var xpPenaltyPerUnit: Int
    var icon: String
    var colorHex: String
}

@MainActor
@Observable
final class OnboardingCoordinator {
    var step: OnboardingStep = .scan

    var q1Name: String = ""
    var q2Building: String = ""
    var q3Weakness: String = ""
    var q4Seriousness: Double = 5
    var wakeTime: Date = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: .now) ?? .now
    var sleepTime: Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now) ?? .now
    var q6GoalsText: String = ""
    var goalDrafts: [GoalDraft] = []
    var signatureHash: String = ""

    func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func back() {
        guard let prev = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = prev
    }

    func complete(modelContext: ModelContext) throws {
        let player = Player(
            username: q1Name.trimmingCharacters(in: .whitespacesAndNewlines),
            signatureHash: signatureHash,
            wakeTime: wakeTime,
            sleepTime: sleepTime,
            focusHoursStart: wakeTime,
            focusHoursEnd: sleepTime,
            restHoursStart: sleepTime,
            restHoursEnd: wakeTime,
            dailyResetTime: Calendar.current.date(byAdding: .minute, value: -30, to: wakeTime) ?? wakeTime,
            notificationsVerdict: true,
            notificationsQuests: true,
            notificationsViolations: true,
            notificationsMorningBrief: true,
            isLightModeEnabled: false,
            friendCode: Self.generateFriendCode()
        )

        for draft in goalDrafts {
            let goal = Goal(
                name: draft.name,
                category: draft.category,
                goalType: draft.goalType,
                targetValue: draft.targetValue,
                unit: draft.unit,
                isCapGoal: draft.isCapGoal,
                xpPerUnit: draft.xpPerUnit,
                xpPenaltyPerUnit: draft.xpPenaltyPerUnit,
                isActive: true,
                colorHex: draft.colorHex,
                icon: draft.icon,
                startDate: Date(),
                player: player
            )
            player.goals.append(goal)
            modelContext.insert(goal)
        }

        modelContext.insert(player)
        try modelContext.save()
    }

    private static func generateFriendCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement() ?? "X" })
    }
}

struct OnboardingHostView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var coordinator = OnboardingCoordinator()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.bg.primary.ignoresSafeArea()
            stepView
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var stepView: some View {
        switch coordinator.step {
        case .scan:
            ScanView { coordinator.advance() }
        case .q1Name:
            InterrogationView(
                kind: .name,
                textValue: $coordinator.q1Name,
                multilineValue: .constant(""),
                sliderValue: .constant(5),
                wakeTime: .constant(.now),
                sleepTime: .constant(.now),
                onContinue: coordinator.advance
            )
        case .q2Goal:
            InterrogationView(
                kind: .building,
                textValue: .constant(""),
                multilineValue: $coordinator.q2Building,
                sliderValue: .constant(5),
                wakeTime: .constant(.now),
                sleepTime: .constant(.now),
                onContinue: coordinator.advance
            )
        case .q3Weakness:
            InterrogationView(
                kind: .weakness,
                textValue: .constant(""),
                multilineValue: $coordinator.q3Weakness,
                sliderValue: .constant(5),
                wakeTime: .constant(.now),
                sleepTime: .constant(.now),
                onContinue: coordinator.advance
            )
        case .q4Serious:
            InterrogationView(
                kind: .seriousness,
                textValue: .constant(""),
                multilineValue: .constant(""),
                sliderValue: $coordinator.q4Seriousness,
                wakeTime: .constant(.now),
                sleepTime: .constant(.now),
                onContinue: coordinator.advance
            )
        case .q5Schedule:
            InterrogationView(
                kind: .schedule,
                textValue: .constant(""),
                multilineValue: .constant(""),
                sliderValue: .constant(5),
                wakeTime: $coordinator.wakeTime,
                sleepTime: $coordinator.sleepTime,
                onContinue: coordinator.advance
            )
        case .q6Goals:
            InterrogationView(
                kind: .goalsPrompt,
                textValue: .constant(""),
                multilineValue: $coordinator.q6GoalsText,
                sliderValue: .constant(5),
                wakeTime: .constant(.now),
                sleepTime: .constant(.now),
                onContinue: coordinator.advance
            )
        case .goalSetup:
            GoalSetupView(drafts: $coordinator.goalDrafts) {
                coordinator.advance()
            }
        case .contract:
            ContractView { signatureHash in
                coordinator.signatureHash = signatureHash
                coordinator.advance()
            }
        case .permissions:
            PermissionsView {
                do {
                    try coordinator.complete(modelContext: modelContext)
                    onComplete()
                } catch {
                    // Keep onboarding active if persistence fails.
                }
            }
        }
    }
}
