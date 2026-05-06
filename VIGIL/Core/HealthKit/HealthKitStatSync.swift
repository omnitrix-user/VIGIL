//
//  HealthKitStatSync.swift
//  VIGIL
//

import Foundation
import SwiftData

/// Applies Health-derived XP totals to **`Player.strength`** (workouts + steps) and **`Player.vitality`** (sleep + mindful) on **`MainActor`**, driven by **`HealthKitManager`** reads.
enum HealthKitStatSync {
    private static let ledgerKey = "vigil.healthKit.dailySyncedTotals.v2"

    private struct DayTotals: Codable, Equatable {
        var strength: Int
        var vitality: Int
    }

    /// Fetches current Health payloads (runs HealthKit completions off the caller until suspension), computes targets, reconciles deltas for **today**, and saves `modelContext` on **`MainActor`**.
    @MainActor
    static func syncTodayHealthIntoPlayer(
        player: Player,
        modelContext: ModelContext,
        manager: HealthKitManager = HealthKitManager.shared
    ) async {
        async let workouts = manager.fetchTodayWorkouts()
        async let steps = manager.fetchTodaySteps()
        async let sleep = manager.fetchLastNightSleep()
        async let mindful = manager.fetchTodayMindfulMinutes()

        let w = await workouts
        let s = await steps
        let sl = await sleep
        let mindfulMinutes = await mindful

        let workoutXP = w.reduce(0) { partial, item in
            partial + HealthKitAdapter.workoutXP(minutes: item.durationMinutes, heartRate: item.avgHeartRate)
        }
        let stepXP = HealthKitAdapter.stepsXP(steps: s)
        let strengthTarget = workoutXP + stepXP

        var spiritTarget = HealthKitAdapter.mindfulXP(minutes: mindfulMinutes)
        if let summary = sl {
            spiritTarget += HealthKitAdapter.sleepXP(hours: summary.totalHours, quality: summary.quality)
        }

        let dayId = calendarDayString(for: Date())
        await applyTargets(
            dayId: dayId,
            player: player,
            modelContext: modelContext,
            strengthTarget: strengthTarget,
            spiritTarget: spiritTarget
        )
    }

    @MainActor
    private static func applyTargets(
        dayId: String,
        player: Player,
        modelContext: ModelContext,
        strengthTarget: Int,
        spiritTarget: Int
    ) async {
        var ledger = loadLedger()
        let previous = ledger[dayId] ?? DayTotals(strength: 0, vitality: 0)

        let dStrength = strengthTarget - previous.strength
        let dSpirit = spiritTarget - previous.vitality

        if dStrength != 0 {
            var block = player.strength
            block.currentXP = max(0, block.currentXP + dStrength)
            if dStrength > 0 {
                block.totalXP += dStrength
            }
            player.strength = block
        }

        if dSpirit != 0 {
            var block = player.vitality
            block.currentXP = max(0, block.currentXP + dSpirit)
            if dSpirit > 0 {
                block.totalXP += dSpirit
            }
            player.vitality = block
        }

        ledger[dayId] = DayTotals(strength: strengthTarget, vitality: spiritTarget)
        saveLedger(ledger)

        try? await modelContext.save()
    }

    private static func loadLedger() -> [String: DayTotals] {
        guard let data = UserDefaults.standard.data(forKey: ledgerKey) else { return [:] }
        return (try? JSONDecoder().decode([String: DayTotals].self, from: data)) ?? [:]
    }

    private static func saveLedger(_ ledger: [String: DayTotals]) {
        guard let data = try? JSONEncoder().encode(ledger) else { return }
        UserDefaults.standard.set(data, forKey: ledgerKey)
    }

    private static func calendarDayString(for date: Date) -> String {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day], from: date)
        guard let y = c.year, let m = c.month, let d = c.day else { return "" }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
