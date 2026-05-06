import Foundation
import SwiftData

@MainActor
struct WelcomeTrigger {
    func fire(player: Player, modelContext: ModelContext) async {
        let weakest = weakestStat(for: player)
        let primaryGoal = player.goals.first
        let firstDistraction = player.goals.first(where: { $0.isCapGoal || $0.category == .discipline })

        let weakestQuest = Quest(
            title: "AWAKENING: SHORE YOUR WEAKEST STAT",
            questDescription: "Player. Your lowest stat is exposed. Execute one focused session.",
            questType: .awakening,
            assignedAt: Date(),
            deadline: Date().addingTimeInterval(24 * 3600),
            xpReward: 75,
            xpPenalty: 40,
            statTarget: weakest,
            status: .active,
            failureConsequence: .xpLoss,
            isReactive: false,
            triggerPattern: "welcome.weakest",
            verificationMethod: .manual,
            player: player
        )
        modelContext.insert(weakestQuest)

        if let primaryGoal {
            let goalQuest = Quest(
                title: "AWAKENING: PRIMARY DIRECTIVE",
                questDescription: "Player. Advance \(primaryGoal.name) today. Output is mandatory.",
                questType: .awakening,
                assignedAt: Date(),
                deadline: Date().addingTimeInterval(24 * 3600),
                xpReward: 80,
                xpPenalty: 45,
                statTarget: primaryGoal.category,
                status: .active,
                failureConsequence: .xpLoss,
                isReactive: false,
                triggerPattern: "welcome.primary",
                verificationMethod: .manual,
                player: player
            )
            modelContext.insert(goalQuest)
        }

        if let firstDistraction {
            let distractionQuest = Quest(
                title: "AWAKENING: RESIST DECLARED DISTRACTION",
                questDescription: "Player. Resist \(firstDistraction.name) for 4 hours today.",
                questType: .awakening,
                assignedAt: Date(),
                deadline: Date().addingTimeInterval(24 * 3600),
                xpReward: 90,
                xpPenalty: 60,
                statTarget: .discipline,
                status: .active,
                failureConsequence: .xpLoss,
                isReactive: true,
                triggerPattern: "welcome.distraction.\(firstDistraction.id.uuidString)",
                verificationMethod: .manual,
                player: player
            )
            modelContext.insert(distractionQuest)
        }
        try? modelContext.save()
    }

    private func weakestStat(for player: Player) -> StatCategory {
        let pairs: [(StatCategory, Int)] = [
            (.intelligence, player.intelligence.totalXP),
            (.strength, player.strength.totalXP),
            (.vitality, player.vitality.totalXP),
            (.discipline, player.discipline.totalXP),
        ]
        return pairs.min(by: { $0.1 < $1.1 })?.0 ?? .discipline
    }
}
