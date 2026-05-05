//
//  SleepSummary.swift
//  VIGIL
//

import Foundation

struct SleepSummary: Sendable, Equatable {
    var totalHours: Double
    var quality: SleepQuality
    var startTime: Date
    var endTime: Date
}
