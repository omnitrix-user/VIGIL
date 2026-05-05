//
//  AIVerdict.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class AIVerdict {
    var id: UUID
    var deliveredAt: Date
    var verdictType: VerdictType
    var message: String
    var consequenceApplied: ConsequenceType?
    var xpDelta: Int
    var rankChangeDelta: Int
    var titlesStripped: [String]
    var titlesAwarded: [String]
    var questsIssued: [UUID]
    var triggerContext: String
    var wasAcknowledged: Bool
    var acknowledgedAt: Date?
    var aiFollowUpMessage: String?

    var player: Player?
    var dayLog: DayLog?

    init(
        id: UUID = UUID(),
        deliveredAt: Date = Date(),
        verdictType: VerdictType = VerdictType.observation,
        message: String = "",
        consequenceApplied: ConsequenceType? = nil,
        xpDelta: Int = 0,
        rankChangeDelta: Int = 0,
        titlesStripped: [String] = [],
        titlesAwarded: [String] = [],
        questsIssued: [UUID] = [],
        triggerContext: String = "",
        wasAcknowledged: Bool = false,
        acknowledgedAt: Date? = nil,
        aiFollowUpMessage: String? = nil,
        player: Player? = nil,
        dayLog: DayLog? = nil
    ) {
        self.id = id
        self.deliveredAt = deliveredAt
        self.verdictType = verdictType
        self.message = message
        self.consequenceApplied = consequenceApplied
        self.xpDelta = xpDelta
        self.rankChangeDelta = rankChangeDelta
        self.titlesStripped = titlesStripped
        self.titlesAwarded = titlesAwarded
        self.questsIssued = questsIssued
        self.triggerContext = triggerContext
        self.wasAcknowledged = wasAcknowledged
        self.acknowledgedAt = acknowledgedAt
        self.aiFollowUpMessage = aiFollowUpMessage
        self.player = player
        self.dayLog = dayLog
    }
}
