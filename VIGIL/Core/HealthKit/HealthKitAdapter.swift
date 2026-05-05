//
//  HealthKitAdapter.swift
//  VIGIL
//

import Foundation

enum HealthKitAdapter {
    /// 3 XP per minute, +25% if average heart rate indicates effort zone (> 140 bpm).
    static func workoutXP(minutes: Int, heartRate: Int?) -> Int {
        let base = minutes * 3
        guard let heartRate, heartRate > 140 else { return base }
        return Int((Double(base) * 1.25).rounded())
    }

    /// 50 XP per 1000 steps (integer thousands).
    static func stepsXP(steps: Int) -> Int {
        50 * (max(0, steps) / 1000)
    }

    /// 200 XP when sleep is 7+ hours and quality is good or excellent.
    static func sleepXP(hours: Double, quality: SleepQuality) -> Int {
        guard hours >= 7, quality == .good || quality == .excellent else { return 0 }
        return 200
    }

    /// 2.5 XP per mindful minute, rounded to integer.
    static func mindfulXP(minutes: Double) -> Int {
        Int((minutes * 2.5).rounded())
    }
}
