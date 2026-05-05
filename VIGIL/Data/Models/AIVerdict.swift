//
//  AIVerdict.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class AIVerdict {
    var id: UUID = UUID()
    var deliveredAt: Date = Date()
    var verdictType: VerdictType = .observation
    var message: String = ""
    var consequenceApplied: ConsequenceType?
    var xpDelta: Int = 0
    var rankChangeDelta: Int = 0
    var titlesStripped: [String] = []
    var titlesAwarded: [String] = []
    var questsIssued: [UUID] = []
    var triggerContext: String = ""
    var wasAcknowledged: Bool = false
    var acknowledgedAt: Date?
    var aiFollowUpMessage: String?

    @Relationship(inverse: \Player.verdicts)
    var player: Player?
    @Relationship(inverse: \DayLog.verdict)
    var dayLog: DayLog?
}
