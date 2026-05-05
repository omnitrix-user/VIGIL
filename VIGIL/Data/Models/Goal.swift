//
//  Goal.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID = UUID()
    var name: String = ""
    var category: StatCategory = .intellect
    var goalType: GoalType = .duration
    var targetValue: Double = 0
    var unit: String = ""
    var isCapGoal: Bool = false
    var xpPerUnit: Int = 0
    var xpPenaltyPerUnit: Int = 0
    var isActive: Bool = true
    var colorHex: String = ""
    var icon: String = ""
    var startDate: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \GoalCompletion.goal)
    var completions: [GoalCompletion] = []

    @Relationship(inverse: \Player.goals)
    var player: Player?
}
