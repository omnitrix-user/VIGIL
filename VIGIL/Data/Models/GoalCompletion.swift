//
//  GoalCompletion.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class GoalCompletion {
    var id: UUID
    var loggedAt: Date
    var value: Double

    var goal: Goal?
    var dayLog: DayLog?

    init(
        id: UUID = UUID(),
        loggedAt: Date = Date(),
        value: Double = 0,
        goal: Goal? = nil,
        dayLog: DayLog? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.value = value
        self.goal = goal
        self.dayLog = dayLog
    }
}
