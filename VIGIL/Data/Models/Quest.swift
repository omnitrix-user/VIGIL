//
//  Quest.swift
//  VIGIL
//

import Foundation
import SwiftData

@Model
final class Quest {
    var id: UUID
    var title: String
    var questDescription: String
    var questType: QuestType
    var assignedAt: Date
    var deadline: Date?
    var xpReward: Int
    var xpPenalty: Int
    var statTarget: StatCategory
    var status: QuestStatus
    var failureConsequence: ConsequenceType
    var isReactive: Bool
    var triggerPattern: String?
    var verificationMethod: VerificationMethod

    var player: Player?

    init(
        id: UUID = UUID(),
        title: String = "",
        questDescription: String = "",
        questType: QuestType = QuestType.shadow,
        assignedAt: Date = Date(),
        deadline: Date? = nil,
        xpReward: Int = 0,
        xpPenalty: Int = 0,
        statTarget: StatCategory = StatCategory.intellect,
        status: QuestStatus = QuestStatus.active,
        failureConsequence: ConsequenceType = ConsequenceType.xpLoss,
        isReactive: Bool = false,
        triggerPattern: String? = nil,
        verificationMethod: VerificationMethod = VerificationMethod.manual,
        player: Player? = nil
    ) {
        self.id = id
        self.title = title
        self.questDescription = questDescription
        self.questType = questType
        self.assignedAt = assignedAt
        self.deadline = deadline
        self.xpReward = xpReward
        self.xpPenalty = xpPenalty
        self.statTarget = statTarget
        self.status = status
        self.failureConsequence = failureConsequence
        self.isReactive = isReactive
        self.triggerPattern = triggerPattern
        self.verificationMethod = verificationMethod
        self.player = player
    }
}
