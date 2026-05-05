//
//  PhoneBlock.swift
//  VIGIL
//

import Foundation
import SwiftData

/// In-memory representation of a scheduled no-phone block (mirrors persisted `PhoneBlockRecord`).
struct PhoneBlock: Identifiable, Equatable, Sendable {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var goalId: UUID
    var isActive: Bool
    var wasViolated: Bool
    var xpReward: Int

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        goalId: UUID,
        isActive: Bool = true,
        wasViolated: Bool = false,
        xpReward: Int = 0
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.goalId = goalId
        self.isActive = isActive
        self.wasViolated = wasViolated
        self.xpReward = xpReward
    }
}

extension PhoneBlock {
    init(record: PhoneBlockRecord) {
        self.id = record.id
        self.startTime = record.startTime
        self.endTime = record.endTime
        self.goalId = record.goalId
        self.isActive = record.isActive
        self.wasViolated = record.wasViolated
        self.xpReward = record.xpReward
    }
}
