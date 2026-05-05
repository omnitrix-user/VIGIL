//
//  Quest.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class Quest {
    var id: UUID = UUID()
    var title: String = ""
    var questDescription: String = ""
    var questType: QuestType = .shadow
    var assignedAt: Date = Date()
    var deadline: Date?
    var xpReward: Int = 0
    var xpPenalty: Int = 0
    var statTarget: StatCategory = .intellect
    var status: QuestStatus = .active
    var failureConsequence: ConsequenceType = .xpLoss
    var isReactive: Bool = false
    var triggerPattern: String?
    var verificationMethod: VerificationMethod = .manual

    @Relationship(inverse: \Player.quests)
    var player: Player?
}
