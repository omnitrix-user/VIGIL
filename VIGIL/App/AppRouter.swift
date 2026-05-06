//
//  AppRouter.swift
//  VIGIL
//

import Foundation
import Observation

@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case dashboard
        case quests
        case profile
    }

    enum BootContext {
        case standard
        case postOnboarding
        case newDay
        case postPunishment
        case streakMilestone
        case rankChange
    }

    private enum DefaultsKey {
        static let lastBootSequenceDay = "vigil.lastBootSequenceDay"
    }

    var shouldShowBoot: Bool = false
    var bootContext: BootContext = .standard
    var activeTab: Tab = .dashboard
    var hasNewQuest: Bool = false

    /// Recomputes `shouldShowBoot` from calendar day and `hasNewQuest`.
    func refreshBootTriggerState() {
        let todayId = Self.calendarDayIdentifier(for: Date())
        let lastId = UserDefaults.standard.string(forKey: DefaultsKey.lastBootSequenceDay)
        let isFirstOpenToday = lastId != todayId
        shouldShowBoot = isFirstOpenToday || hasNewQuest
        bootContext = isFirstOpenToday ? .newDay : .standard
    }

    /// Call when the boot sequence finishes (timer or future skip control).
    func completeBootSequence() {
        let todayId = Self.calendarDayIdentifier(for: Date())
        UserDefaults.standard.set(todayId, forKey: DefaultsKey.lastBootSequenceDay)
        hasNewQuest = false
        shouldShowBoot = false
    }

    /// Call when a new quest is issued while the app may be backgrounded or active.
    func setHasNewQuest(_ value: Bool) {
        hasNewQuest = value
        if value { bootContext = .rankChange }
        refreshBootTriggerState()
    }

    private static func calendarDayIdentifier(for date: Date) -> String {
        let calendar = Calendar.current
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        guard let y = c.year, let m = c.month, let d = c.day else { return "" }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
