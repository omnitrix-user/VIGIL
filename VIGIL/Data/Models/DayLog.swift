//
//  DayLog.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class DayLog {
    var id: UUID = UUID()
    var date: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \GoalCompletion.dayLog)
    var goalCompletions: [GoalCompletion] = []

    var phoneBlocksScheduled: Int = 0
    var phoneBlocksKept: Int = 0
    var sleepHours: Double?
    var sleepQuality: SleepQuality?
    var workoutMinutes: Int?
    var heartRateAvg: Int?
    var disciplineScore: Double = 0
    var totalXPEarned: Int = 0
    var totalXPLost: Int = 0
    @Relationship(inverse: \AIVerdict.dayLog)
    var verdict: AIVerdict?
    var isPerfectDay: Bool = false
    var didShowUp: Bool = false

    @Relationship(inverse: \Player.dailyLogs)
    var player: Player?
}
