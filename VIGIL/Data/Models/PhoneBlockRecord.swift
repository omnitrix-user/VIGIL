//
//  PhoneBlockRecord.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class PhoneBlockRecord {
    var id: UUID
    var goalId: UUID
    var startTime: Date
    var endTime: Date
    /// Matches `DeviceActivityName.rawValue` registered with `DeviceActivityCenter`.
    var deviceActivityNameRaw: String
    var isActive: Bool
    var wasViolated: Bool
    var xpReward: Int
    /// After grace, first incident issues warning only; second applies penalty (persisted for extension restarts).
    var violationWarningIssued: Bool

    init(
        id: UUID = UUID(),
        goalId: UUID,
        startTime: Date,
        endTime: Date,
        deviceActivityNameRaw: String,
        isActive: Bool = true,
        wasViolated: Bool = false,
        xpReward: Int = 0,
        violationWarningIssued: Bool = false
    ) {
        self.id = id
        self.goalId = goalId
        self.startTime = startTime
        self.endTime = endTime
        self.deviceActivityNameRaw = deviceActivityNameRaw
        self.isActive = isActive
        self.wasViolated = wasViolated
        self.xpReward = xpReward
        self.violationWarningIssued = violationWarningIssued
    }
}
