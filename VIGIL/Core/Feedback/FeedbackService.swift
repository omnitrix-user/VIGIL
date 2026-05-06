import Foundation
import SwiftData

@MainActor
final class FeedbackService {
    static let shared = FeedbackService()

    var activeSubmitter: FeedbackSubmitting

    private init(activeSubmitter: FeedbackSubmitting = EmailFeedbackSubmitter()) {
        self.activeSubmitter = activeSubmitter
    }

    func submit(_ entry: FeedbackEntry, modelContext: ModelContext) async throws {
        modelContext.insert(entry)
        try modelContext.save()

        let diagnostics = entry.includeDiagnostics ? makeDiagnostics(modelContext: modelContext) : nil
        do {
            try await activeSubmitter.submit(entry, diagnostics: diagnostics)
            entry.submitted = true
            try modelContext.save()
        } catch {
            entry.submitted = false
            try? modelContext.save()
            throw error
        }
    }

    private func makeDiagnostics(modelContext: ModelContext) -> DiagnosticsBundle {
        let player = (try? modelContext.fetch(FetchDescriptor<Player>()).first)
        let verdicts = (try? modelContext.fetch(FetchDescriptor<AIVerdict>())) ?? []
        let snapshot = PlayerAnonymizedSnapshot(
            currentRank: player?.currentRank.rawValue ?? "E",
            totalXP: player?.totalXP ?? 0,
            daysActive: player.map { Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 0 } ?? 0,
            streakLength: player?.showedUpStreak ?? 0,
            intelligenceXP: player?.intelligence.totalXP ?? 0,
            strengthXP: player?.strength.totalXP ?? 0,
            vitalityXP: player?.vitality.totalXP ?? 0,
            disciplineXP: player?.discipline.totalXP ?? 0
        )
        return DiagnosticsBundle(
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0",
            buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0",
            iOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: "iPhone",
            lastFiftyLogLines: [],
            playerSnapshot: snapshot,
            lastFiveSystemMessages: Array(verdicts.sorted(by: { $0.deliveredAt > $1.deliveredAt }).prefix(5).map(\.message))
        )
    }
}
