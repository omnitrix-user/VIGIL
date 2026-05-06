import Foundation
import SwiftData

@Model
final class CategorizationCache {
    var key: String
    var payload: Data
    var createdAt: Date
    var overriddenCategoryRaw: String?

    init(
        key: String,
        payload: Data,
        createdAt: Date = Date(),
        overriddenCategoryRaw: String? = nil
    ) {
        self.key = key
        self.payload = payload
        self.createdAt = createdAt
        self.overriddenCategoryRaw = overriddenCategoryRaw
    }

    var overriddenCategory: ActivityCategory? {
        guard let overriddenCategoryRaw else { return nil }
        return ActivityCategory(rawValue: overriddenCategoryRaw)
    }
}

enum CategorizationCacheKey {
    static func make(for event: ActivityEvent) -> String {
        let rounded = Int(event.startedAt.timeIntervalSince1970 / 60.0)
        return "\(event.source.rawValue)|\(event.identifier)|\(rounded)|\(Int(event.durationMinutes.rounded()))"
    }
}
