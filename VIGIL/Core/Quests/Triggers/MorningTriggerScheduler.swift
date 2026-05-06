import BackgroundTasks
import Foundation
import SwiftData

@MainActor
final class MorningTriggerScheduler {
    static let shared = MorningTriggerScheduler()
    static let taskIdentifier = "com.vigil.morning.refresh"
    weak var modelContext: ModelContext?

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            Task { @MainActor in
                await self.handle(task: refreshTask)
            }
        }
    }

    func schedule(for player: Player) {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = player.wakeTime.addingTimeInterval(-15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(task: BGAppRefreshTask) async {
        guard let context = modelContext else {
            task.setTaskCompleted(success: false)
            return
        }
        var playerFetch = FetchDescriptor<Player>()
        playerFetch.fetchLimit = 1
        guard let player = try? context.fetch(playerFetch).first else {
            task.setTaskCompleted(success: false)
            return
        }

        let stat: StatCategory
        let roll = Int.random(in: 1...10)
        if roll <= 6 {
            let goal = player.goals.filter(\.isActive).min(by: { $0.targetValue < $1.targetValue })
            stat = goal?.category ?? .discipline
        } else if roll <= 9 {
            stat = .discipline
        } else {
            stat = .strength
        }

        let trigger = QuestTrigger(type: .shadow, pattern: "morning", statTarget: stat, severity: 2)
        let quest = await VIGILAIService.shared.generateQuest(trigger: trigger)
        quest.player = player
        context.insert(quest)
        try? context.save()

        await NotificationManager.shared.postMorningQuestNotification(day: player.showedUpStreak + 1, questTitle: quest.title, player: player)
        schedule(for: player)
        task.setTaskCompleted(success: true)
    }
}
