import Foundation

struct PostHogFeedbackSubmitter: FeedbackSubmitting {
    func submit(_ entry: FeedbackEntry, diagnostics: DiagnosticsBundle?) async throws {
        _ = entry
        _ = diagnostics
        fatalError("Phase 2 — PostHog integration pending")
    }
}
