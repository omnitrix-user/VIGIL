//
//  WorkoutSummary.swift
//  VIGIL
//

import Foundation

struct WorkoutSummary: Sendable, Equatable {
    var durationMinutes: Int
    var calories: Double
    var avgHeartRate: Int?
    var startTime: Date
    var endTime: Date
}
