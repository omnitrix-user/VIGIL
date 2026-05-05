//
//  Player.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID = UUID()
    var username: String = ""
    var createdAt: Date = Date()
    var currentRank: Rank = .E
    var totalXP: Int = 0
    var intellect: StatBlock = StatBlock(
        currentXP: 0,
        totalXP: 0,
        level: 1,
        xpToNextLevel: 0,
        debuffActive: false,
        debuffExpiresAt: nil,
        weekHistory: []
    )
    var strength: StatBlock = StatBlock(
        currentXP: 0,
        totalXP: 0,
        level: 1,
        xpToNextLevel: 0,
        debuffActive: false,
        debuffExpiresAt: nil,
        weekHistory: []
    )
    var spirit: StatBlock = StatBlock(
        currentXP: 0,
        totalXP: 0,
        level: 1,
        xpToNextLevel: 0,
        debuffActive: false,
        debuffExpiresAt: nil,
        weekHistory: []
    )
    var discipline: StatBlock = StatBlock(
        currentXP: 0,
        totalXP: 0,
        level: 1,
        xpToNextLevel: 0,
        debuffActive: false,
        debuffExpiresAt: nil,
        weekHistory: []
    )
    var perfectDayStreak: Int = 0
    var showedUpStreak: Int = 0
    var longestPerfectStreak: Int = 0
    var longestShowedUpStreak: Int = 0
    var titles: [String] = []
    var activeTitle: String?
    var isNewGamePlus: Bool = false
    var newGamePlusCount: Int = 0
    var hasGoldenCrown: Bool = false
    var signatureHash: String = ""
    var shamePostsEnabled: Bool = false
    var wakeTime: Date = Date()
    var sleepTime: Date = Date()
    var focusHoursStart: Date = Date()
    var focusHoursEnd: Date = Date()
    var restHoursStart: Date = Date()
    var restHoursEnd: Date = Date()
    var dailyResetTime: Date = Date()
    var notificationsVerdict: Bool = false
    var notificationsQuests: Bool = false
    var notificationsViolations: Bool = false
    var notificationsMorningBrief: Bool = false
    var isLightModeEnabled: Bool = false
    var awakeningQuestCompleted: Bool = false
    var hasUnawokenTag: Bool = false
    var friendCode: String = ""
    var supabaseUserId: String?

    @Relationship(deleteRule: .cascade, inverse: \Goal.player)
    var goals: [Goal] = []

    @Relationship(deleteRule: .cascade, inverse: \Quest.player)
    var quests: [Quest] = []

    @Relationship(deleteRule: .cascade, inverse: \DayLog.player)
    var dailyLogs: [DayLog] = []

    @Relationship(deleteRule: .cascade, inverse: \AIVerdict.player)
    var verdicts: [AIVerdict] = []
}
