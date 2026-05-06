//
//  AIModels.swift
//  VIGIL
//

import Foundation

struct AIContext: Codable, Sendable {
    var intelligence: StatBlock
    var strength: StatBlock
    var vitality: StatBlock
    var discipline: StatBlock
    var activeGoals: [GoalSnapshot]
    var activeQuests: [QuestSnapshot]
    var last7DayLogs: [DayLogSnapshot]
    var streak: Int
    var rank: Rank
    var titles: [String]
}

struct GoalSnapshot: Codable, Sendable {
    var id: UUID
    var name: String
    var category: StatCategory
    var goalType: GoalType
    var targetValue: Double
    var isCapGoal: Bool
}

struct QuestSnapshot: Codable, Sendable {
    var id: UUID
    var title: String
    var questType: QuestType
    var status: QuestStatus
    var deadline: Date?
    var statTarget: StatCategory
}

struct DayLogSnapshot: Codable, Sendable {
    var date: Date
    var disciplineScore: Double
    var totalXPEarned: Int
    var totalXPLost: Int
    var isPerfectDay: Bool
    var didShowUp: Bool
    var phoneBlocksScheduled: Int
    var phoneBlocksKept: Int
}

struct QuestTrigger: Codable, Sendable {
    enum TriggerType: String, Codable, Sendable {
        case shadow
        case ascension
        case reckoning
    }

    var type: TriggerType
    var pattern: String?
    var statTarget: StatCategory
    var severity: Int
}

enum ViolationType: String, Codable, Sendable {
    case noPhoneBlock
    case missedGoal
    case questFailure
    case inactivity
    case custom
}

struct PatternInsight: Codable, Sendable {
    var weakHours: [Int]
    var failurePatterns: [String]
    var statImbalances: [String: Double]
}

struct CompletedSession: Codable, Sendable {
    var goalId: UUID
    var duration: Double
    var xpEarned: Int
    var completedAt: Date

    // Backward-compatible surface for existing timer usage.
    var durationMinutes: Double { duration }
    var xpAwarded: Int { xpEarned }

    init(goalId: UUID, duration: Double, xpEarned: Int, completedAt: Date = Date()) {
        self.goalId = goalId
        self.duration = duration
        self.xpEarned = xpEarned
        self.completedAt = completedAt
    }

    init(
        goalId: UUID,
        durationMinutes: Double,
        valueLogged: Double = 0,
        xpAwarded: Int,
        wasCompleted: Bool
    ) {
        self.goalId = goalId
        self.duration = durationMinutes
        self.xpEarned = wasCompleted ? xpAwarded : 0
        self.completedAt = Date()
        _ = valueLogged
    }
}
