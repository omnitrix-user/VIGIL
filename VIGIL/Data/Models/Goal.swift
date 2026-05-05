//
//  Goal.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var name: String
    var category: StatCategory
    var goalType: GoalType
    var targetValue: Double
    var unit: String
    var isCapGoal: Bool
    var xpPerUnit: Int
    var xpPenaltyPerUnit: Int
    var isActive: Bool
    var colorHex: String
    var icon: String
    var startDate: Date

    @Relationship(deleteRule: .cascade, inverse: \GoalCompletion.goal)
    var completions: [GoalCompletion]

    var player: Player?

    init(
        id: UUID = UUID(),
        name: String = "",
        category: StatCategory = StatCategory.intellect,
        goalType: GoalType = GoalType.duration,
        targetValue: Double = 0,
        unit: String = "",
        isCapGoal: Bool = false,
        xpPerUnit: Int = 0,
        xpPenaltyPerUnit: Int = 0,
        isActive: Bool = true,
        colorHex: String = "",
        icon: String = "",
        startDate: Date = Date(),
        player: Player? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.goalType = goalType
        self.targetValue = targetValue
        self.unit = unit
        self.isCapGoal = isCapGoal
        self.xpPerUnit = xpPerUnit
        self.xpPenaltyPerUnit = xpPenaltyPerUnit
        self.isActive = isActive
        self.colorHex = colorHex
        self.icon = icon
        self.startDate = startDate
        self.completions = []
        self.player = player
    }
}
