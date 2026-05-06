import Foundation
import Observation
import SwiftData

enum QuestTriggerSource: Codable, Sendable {
    case welcome
    case morning
    case idle(hoursInactive: Int)
    case reactive(reason: ReactiveTrigger)
}

enum ReactiveTrigger: String, Codable, Sendable {
    case failurePattern
    case streakBreak
    case rankDrop
}

@MainActor
@Observable
final class QuestTriggerService {
    static let shared = QuestTriggerService()

    private enum DefaultsKey {
        static let onboardingCompleted = "vigil.onboarding.completed"
        static let onboardingWelcomeIssued = "vigil.onboarding.welcomeIssued"
    }

    private let welcomeTrigger = WelcomeTrigger()
    private let idleTrigger = IdleTriggerService()

    private init() {}

    func evaluateTriggers(modelContext: ModelContext) async {
        var playerFetch = FetchDescriptor<Player>()
        playerFetch.fetchLimit = 1
        guard let player = try? modelContext.fetch(playerFetch).first else { return }
        player.lastActiveAt = Date()
        try? modelContext.save()

        let activeCount = player.quests.filter { $0.status == .active }.count
        guard activeCount < 5 else { return }

        if UserDefaults.standard.bool(forKey: DefaultsKey.onboardingCompleted),
           !UserDefaults.standard.bool(forKey: DefaultsKey.onboardingWelcomeIssued) {
            await welcomeTrigger.fire(player: player, modelContext: modelContext)
            UserDefaults.standard.set(true, forKey: DefaultsKey.onboardingWelcomeIssued)
            return
        }

        await idleTrigger.evaluate(player: player, modelContext: modelContext)
    }

    func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: DefaultsKey.onboardingCompleted)
        UserDefaults.standard.set(false, forKey: DefaultsKey.onboardingWelcomeIssued)
    }
}
