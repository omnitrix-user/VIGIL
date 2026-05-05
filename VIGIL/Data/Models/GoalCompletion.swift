//
//  GoalCompletion.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class GoalCompletion {
    var id: UUID = UUID()
    var loggedAt: Date = Date()
    var value: Double = 0

    var goal: Goal?
    var dayLog: DayLog?
}
