//
//  QuestVerificationService.swift
//  VIGIL
//

import Foundation
import SwiftData

@MainActor
struct QuestVerificationService {
    static let shared = QuestVerificationService()

    func isQuestVerifiable(_ quest: Quest, modelContext: ModelContext) async -> Bool {
        switch quest.verificationMethod {
        case .healthKit:
            return verifyHealthKitQuest(quest, modelContext: modelContext)
        case .screenTime:
            return verifyScreenTimeQuest(quest, modelContext: modelContext)
        case .timer:
            return verifyTimerQuest(quest, modelContext: modelContext)
        case .manual:
            return true
        case .ai:
            return await verifyAIQuest(quest, modelContext: modelContext)
        }
    }

    private func verifyHealthKitQuest(_ quest: Quest, modelContext: ModelContext) -> Bool {
        guard let player = quest.player else { return false }
        let latest = player.dailyLogs.sorted { $0.date > $1.date }.first
        return (latest?.workoutMinutes ?? 0) > 0 || (latest?.sleepHours ?? 0) > 0
    }

    private func verifyScreenTimeQuest(_ quest: Quest, modelContext: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<PhoneBlockRecord>()
        descriptor.fetchLimit = 256
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        return rows.contains {
            $0.goalId == quest.id && $0.wasViolated == false && $0.isActive == false
        }
    }

    private func verifyTimerQuest(_ quest: Quest, modelContext: ModelContext) -> Bool {
        guard let player = quest.player else { return false }

        // Prefer explicit mapping if triggerPattern stores a goal UUID.
        if let pattern = quest.triggerPattern,
           let goalID = UUID(uuidString: pattern),
           let goal = player.goals.first(where: { $0.id == goalID }) {
            return goal.completions.count > 0
        }

        // Fallback: any goal in the same stat category with logged completion.
        return player.goals.contains { goal in
            goal.category == quest.statTarget && goal.completions.count > 0
        }
    }

    private func verifyAIQuest(_ quest: Quest, modelContext: ModelContext) async -> Bool {
        guard let player = quest.player else { return false }
        let context = AIContext(
            intellect: player.intellect,
            strength: player.strength,
            spirit: player.spirit,
            discipline: player.discipline,
            activeGoals: [],
            activeQuests: [],
            last7DayLogs: [],
            streak: player.perfectDayStreak,
            rank: player.currentRank,
            titles: player.titles
        )
        let message = await VIGILAIService.shared.runMorningBrief(context: context)
        return !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
