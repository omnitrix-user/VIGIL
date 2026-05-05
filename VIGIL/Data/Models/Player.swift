//
//  Player.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var username: String
    var createdAt: Date
    var currentRank: Rank
    var totalXP: Int
    var intellect: StatBlock
    var strength: StatBlock
    var spirit: StatBlock
    var discipline: StatBlock
    var perfectDayStreak: Int
    var showedUpStreak: Int
    var longestPerfectStreak: Int
    var longestShowedUpStreak: Int
    var titles: [String]
    var activeTitle: String?
    var isNewGamePlus: Bool
    var newGamePlusCount: Int
    var hasGoldenCrown: Bool
    var signatureHash: String
    var shamePostsEnabled: Bool
    var wakeTime: Date
    var sleepTime: Date
    var focusHoursStart: Date
    var focusHoursEnd: Date
    var restHoursStart: Date
    var restHoursEnd: Date
    var dailyResetTime: Date
    var notificationsVerdict: Bool
    var notificationsQuests: Bool
    var notificationsViolations: Bool
    var notificationsMorningBrief: Bool
    var isLightModeEnabled: Bool
    var awakeningQuestCompleted: Bool
    var hasUnawokenTag: Bool
    var friendCode: String
    var supabaseUserId: String?

    @Relationship(deleteRule: .cascade, inverse: \Goal.player)
    var goals: [Goal]

    @Relationship(deleteRule: .cascade, inverse: \Quest.player)
    var quests: [Quest]

    @Relationship(deleteRule: .cascade, inverse: \DayLog.player)
    var dailyLogs: [DayLog]

    @Relationship(deleteRule: .cascade, inverse: \AIVerdict.player)
    var verdicts: [AIVerdict]

    init(
        id: UUID = UUID(),
        username: String = "",
        createdAt: Date = Date(),
        currentRank: Rank = Rank.E,
        totalXP: Int = 0,
        perfectDayStreak: Int = 0,
        showedUpStreak: Int = 0,
        longestPerfectStreak: Int = 0,
        longestShowedUpStreak: Int = 0,
        titles: [String] = [],
        activeTitle: String? = nil,
        isNewGamePlus: Bool = false,
        newGamePlusCount: Int = 0,
        hasGoldenCrown: Bool = false,
        signatureHash: String = "",
        shamePostsEnabled: Bool = false,
        wakeTime: Date = Date(),
        sleepTime: Date = Date(),
        focusHoursStart: Date = Date(),
        focusHoursEnd: Date = Date(),
        restHoursStart: Date = Date(),
        restHoursEnd: Date = Date(),
        dailyResetTime: Date = Date(),
        notificationsVerdict: Bool = false,
        notificationsQuests: Bool = false,
        notificationsViolations: Bool = false,
        notificationsMorningBrief: Bool = false,
        isLightModeEnabled: Bool = false,
        awakeningQuestCompleted: Bool = false,
        hasUnawokenTag: Bool = false,
        friendCode: String = "",
        supabaseUserId: String? = nil
    ) {
        let emptyStat = StatBlock(
            currentXP: 0,
            totalXP: 0,
            level: 1,
            xpToNextLevel: 0,
            debuffActive: false,
            debuffExpiresAt: nil,
            weekHistory: []
        )
        self.id = id
        self.username = username
        self.createdAt = createdAt
        self.currentRank = currentRank
        self.totalXP = totalXP
        self.intellect = emptyStat
        self.strength = emptyStat
        self.spirit = emptyStat
        self.discipline = emptyStat
        self.perfectDayStreak = perfectDayStreak
        self.showedUpStreak = showedUpStreak
        self.longestPerfectStreak = longestPerfectStreak
        self.longestShowedUpStreak = longestShowedUpStreak
        self.titles = titles
        self.activeTitle = activeTitle
        self.isNewGamePlus = isNewGamePlus
        self.newGamePlusCount = newGamePlusCount
        self.hasGoldenCrown = hasGoldenCrown
        self.signatureHash = signatureHash
        self.shamePostsEnabled = shamePostsEnabled
        self.wakeTime = wakeTime
        self.sleepTime = sleepTime
        self.focusHoursStart = focusHoursStart
        self.focusHoursEnd = focusHoursEnd
        self.restHoursStart = restHoursStart
        self.restHoursEnd = restHoursEnd
        self.dailyResetTime = dailyResetTime
        self.notificationsVerdict = notificationsVerdict
        self.notificationsQuests = notificationsQuests
        self.notificationsViolations = notificationsViolations
        self.notificationsMorningBrief = notificationsMorningBrief
        self.isLightModeEnabled = isLightModeEnabled
        self.awakeningQuestCompleted = awakeningQuestCompleted
        self.hasUnawokenTag = hasUnawokenTag
        self.friendCode = friendCode
        self.supabaseUserId = supabaseUserId
        self.goals = []
        self.quests = []
        self.dailyLogs = []
        self.verdicts = []
    }
}
