import Foundation

protocol ActivityCategorizing {
    func categorize(
        _ batch: [ActivityEvent],
        playerContext: PlayerCategorizationContext
    ) async throws -> [CategorizedActivity]
}
