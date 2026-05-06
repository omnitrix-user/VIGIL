import BackgroundTasks
import Foundation
import SwiftData

@MainActor
final class IdleCheckScheduler {
    static let shared = IdleCheckScheduler()
    static let taskIdentifier = "com.vigil.idle.check"
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

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(task: BGAppRefreshTask) async {
        guard let modelContext else {
            task.setTaskCompleted(success: false)
            return
        }
        await QuestTriggerService.shared.evaluateTriggers(modelContext: modelContext)
        schedule()
        task.setTaskCompleted(success: true)
    }
}
