//
//  DayLog.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class DayLog {
    var id: UUID
    var date: Date

    @Relationship(deleteRule: .nullify, inverse: \GoalCompletion.dayLog)
    var goalCompletions: [GoalCompletion]

    var phoneBlocksScheduled: Int
    var phoneBlocksKept: Int
    var sleepHours: Double?
    var sleepQuality: SleepQuality?
    var workoutMinutes: Int?
    var heartRateAvg: Int?
    var disciplineScore: Double
    var totalXPEarned: Int
    var totalXPLost: Int
    @Relationship(inverse: \AIVerdict.dayLog)
    var verdict: AIVerdict?
    var isPerfectDay: Bool
    var didShowUp: Bool

    var player: Player?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        phoneBlocksScheduled: Int = 0,
        phoneBlocksKept: Int = 0,
        sleepHours: Double? = nil,
        sleepQuality: SleepQuality? = nil,
        workoutMinutes: Int? = nil,
        heartRateAvg: Int? = nil,
        disciplineScore: Double = 0,
        totalXPEarned: Int = 0,
        totalXPLost: Int = 0,
        verdict: AIVerdict? = nil,
        isPerfectDay: Bool = false,
        didShowUp: Bool = false,
        player: Player? = nil
    ) {
        self.id = id
        self.date = date
        self.goalCompletions = []
        self.phoneBlocksScheduled = phoneBlocksScheduled
        self.phoneBlocksKept = phoneBlocksKept
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.workoutMinutes = workoutMinutes
        self.heartRateAvg = heartRateAvg
        self.disciplineScore = disciplineScore
        self.totalXPEarned = totalXPEarned
        self.totalXPLost = totalXPLost
        self.verdict = verdict
        self.isPerfectDay = isPerfectDay
        self.didShowUp = didShowUp
        self.player = player
    }
}
