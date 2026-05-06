import Foundation
import SwiftData

@MainActor
final class ActivityCategorizationService {
    static let shared = ActivityCategorizationService()

    private let aiCategorizer = FoundationModelsCategorizer()
    private let ruleCategorizer = RuleBasedCategorizer()

    private init() {}

    func categorize(
        events: [ActivityEvent],
        player: Player,
        modelContext: ModelContext
    ) async -> [CategorizedActivity] {
        guard !events.isEmpty else { return [] }
        let context = buildPlayerContext(from: player)

        var output: [CategorizedActivity] = []
        var uncachedEvents: [ActivityEvent] = []
        for event in events {
            let key = CategorizationCacheKey.make(for: event)
            if let cached = cachedResult(key: key, modelContext: modelContext) {
                output.append(cached)
            } else {
                uncachedEvents.append(event)
            }
        }

        if !uncachedEvents.isEmpty {
            let fresh = await categorizeFresh(events: uncachedEvents, context: context).map(normalize)
            for row in fresh {
                if let event = uncachedEvents.first(where: { $0.id == row.activityId }) {
                    let key = CategorizationCacheKey.make(for: event)
                    persist(cacheKey: key, categorized: row, modelContext: modelContext)
                }
            }
            output.append(contentsOf: fresh)
        }

        pruneOldCache(modelContext: modelContext)
        return output
    }

    func overrideCategory(
        event: ActivityEvent,
        category: ActivityCategory,
        modelContext: ModelContext
    ) {
        let key = CategorizationCacheKey.make(for: event)
        var fetch = FetchDescriptor<CategorizationCache>(predicate: #Predicate { $0.key == key })
        fetch.fetchLimit = 1
        let row = (try? modelContext.fetch(fetch))?.first
        if let row {
            row.overriddenCategoryRaw = category.rawValue
        }
        try? modelContext.save()
    }

    private func categorizeFresh(
        events: [ActivityEvent],
        context: PlayerCategorizationContext
    ) async -> [CategorizedActivity] {
        let useFoundation = await foundationModelsAvailable()
        if useFoundation {
            if let result = try? await aiCategorizer.categorize(events, playerContext: context) {
                return result
            }
        }
        return (try? await ruleCategorizer.categorize(events, playerContext: context)) ?? []
    }

    private func foundationModelsAvailable() async -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 18.1, *) {
            return true
        }
        return false
        #endif
    }

    private func buildPlayerContext(from player: Player) -> PlayerCategorizationContext {
        let declaredGoals = player.goals.filter(\.isActive).map {
            DeclaredGoal(name: $0.name, category: $0.category, targetValue: $0.targetValue)
        }
        let declaredDistractions = player.goals.filter { $0.isCapGoal || $0.category == .discipline }.map {
            DeclaredDistraction(name: $0.name, frequency: "Daily", verdict: .limit, capValue: $0.isCapGoal ? $0.targetValue : nil)
        }
        return PlayerCategorizationContext(
            declaredDistractions: declaredDistractions,
            declaredGoals: declaredGoals,
            lifeSituation: "unknown",
            primaryFieldOfFocus: declaredGoals.first?.name ?? "unknown"
        )
    }

    private func cachedResult(key: String, modelContext: ModelContext) -> CategorizedActivity? {
        var fetch = FetchDescriptor<CategorizationCache>(predicate: #Predicate { $0.key == key })
        fetch.fetchLimit = 1
        guard let row = (try? modelContext.fetch(fetch))?.first,
              let decoded = try? JSONDecoder().decode(CategorizedActivity.self, from: row.payload) else { return nil }
        if let override = row.overriddenCategory {
            return CategorizedActivity(
                activityId: decoded.activityId,
                category: override,
                confidence: 1,
                reasoning: "Player override",
                xpAwarded: decoded.xpAwarded,
                statsAffected: decoded.statsAffected,
                isPlayerOverridden: true
            )
        }
        return decoded
    }

    private func persist(cacheKey: String, categorized: CategorizedActivity, modelContext: ModelContext) {
        guard let payload = try? JSONEncoder().encode(categorized) else { return }
        modelContext.insert(CategorizationCache(key: cacheKey, payload: payload))
        try? modelContext.save()
    }

    private func pruneOldCache(modelContext: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        let rows = (try? modelContext.fetch(FetchDescriptor<CategorizationCache>())) ?? []
        rows.filter { $0.createdAt < cutoff }.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }

    private func normalize(_ row: CategorizedActivity) -> CategorizedActivity {
        guard row.confidence < 0.6 || row.category == .unknown else { return row }
        return CategorizedActivity(
            activityId: row.activityId,
            category: .unknown,
            confidence: row.confidence,
            reasoning: row.reasoning,
            xpAwarded: row.xpAwarded,
            statsAffected: row.statsAffected,
            isPlayerOverridden: row.isPlayerOverridden
        )
    }
}
