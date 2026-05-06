import Foundation

struct SentryFeedbackSubmitter: FeedbackSubmitting {
    func submit(_ entry: FeedbackEntry, diagnostics: DiagnosticsBundle?) async throws {
        _ = entry
        _ = diagnostics
        fatalError("Phase 2 — Sentry integration pending")
    }
}
