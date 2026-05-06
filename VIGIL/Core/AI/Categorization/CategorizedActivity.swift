import Foundation

enum ActivityCategory: String, Codable, CaseIterable {
    case training
    case recovery
    case cognition
    case maintenance
    case social
    case distraction
    case declaredDistraction
    case declaredGoal
    case unknown
}

enum ActivityEventSource: String, Codable {
    case healthKitWorkout
    case healthKitCategory
    case screenTime
    case timer
    case manual
}

struct ActivityEvent: Codable, Sendable, Identifiable {
    let id: UUID
    let source: ActivityEventSource
    let identifier: String
    let name: String
    let startedAt: Date
    let durationMinutes: Double
}

struct CategorizedActivity: Codable, Sendable, Identifiable {
    let id: UUID
    let activityId: UUID
    let category: ActivityCategory
    let confidence: Double
    let reasoning: String
    let xpAwarded: Int
    let statsAffected: [StatCategory]
    let isPlayerOverridden: Bool

    init(
        id: UUID = UUID(),
        activityId: UUID,
        category: ActivityCategory,
        confidence: Double,
        reasoning: String,
        xpAwarded: Int = 0,
        statsAffected: [StatCategory] = [],
        isPlayerOverridden: Bool = false
    ) {
        self.id = id
        self.activityId = activityId
        self.category = category
        self.confidence = confidence
        self.reasoning = reasoning
        self.xpAwarded = xpAwarded
        self.statsAffected = statsAffected
        self.isPlayerOverridden = isPlayerOverridden
    }
}
