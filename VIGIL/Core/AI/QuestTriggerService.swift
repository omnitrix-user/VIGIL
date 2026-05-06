import Foundation
import SwiftData

@MainActor
final class QuestTriggerService {
    static let shared = QuestTriggerService()

    private init() {}

    func issueImmediateWelcomeQuest(for player: Player, modelContext: ModelContext) async {
        try? await Task.sleep(for: .seconds(1))
        let trigger = QuestTrigger(type: .shadow, pattern: "welcome", statTarget: .discipline, severity: 1)
        let quest = await VIGILAIService.shared.generateQuest(trigger: trigger)
        quest.player = player
        modelContext.insert(quest)
        try? modelContext.save()
    }

    func issueMorningQuest(for player: Player, modelContext: ModelContext) async {
        let trigger = QuestTrigger(type: .ascension, pattern: "morning", statTarget: .intelligence, severity: 2)
        let quest = await VIGILAIService.shared.generateQuest(trigger: trigger)
        quest.player = player
        modelContext.insert(quest)
        try? modelContext.save()
    }

    func issueIdleQuestIfNeeded(for player: Player, modelContext: ModelContext, inactiveHours: Int) async {
        guard inactiveHours > 18 else { return }
        let trigger = QuestTrigger(type: .reckoning, pattern: "idle>\(inactiveHours)h", statTarget: .discipline, severity: 3)
        let quest = await VIGILAIService.shared.generateQuest(trigger: trigger)
        quest.player = player
        modelContext.insert(quest)
        try? modelContext.save()
    }
}
