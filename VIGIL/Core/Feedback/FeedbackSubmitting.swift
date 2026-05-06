import Foundation

protocol FeedbackSubmitting {
    func submit(_ entry: FeedbackEntry, diagnostics: DiagnosticsBundle?) async throws
}
