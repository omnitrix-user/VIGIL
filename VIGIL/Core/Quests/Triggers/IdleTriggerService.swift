import Foundation
import SwiftData

@MainActor
struct IdleTriggerService {
    func evaluate(player: Player, modelContext: ModelContext) async {
        let inactiveHours = Int(Date().timeIntervalSince(player.lastActiveAt) / 3600.0)
        guard inactiveHours >= 18 else { return }

        if inactiveHours >= 18 && inactiveHours < 48 {
            await NotificationManager.shared.postIdle18hNotification(player: player)
            return
        }

        let recentIdleIssued = player.quests
            .sorted(by: { $0.assignedAt > $1.assignedAt })
            .prefix(3)
            .filter { $0.triggerPattern?.hasPrefix("idle.") == true }
            .count
        if recentIdleIssued >= 3 { return }

        let trigger = QuestTrigger(type: .reckoning, pattern: "idle.\(inactiveHours)h", statTarget: .discipline, severity: 3)
        let quest = await VIGILAIService.shared.generateQuest(trigger: trigger)
        quest.player = player
        modelContext.insert(quest)
        try? modelContext.save()

        if inactiveHours >= 24 * 7 {
            await NotificationManager.shared.postIdle7dNotification(player: player)
        } else {
            await NotificationManager.shared.postIdle48hNotification(player: player)
        }
    }
}
