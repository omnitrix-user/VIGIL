//
//  QuestBoardViewModel.swift
//  VIGIL
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class QuestBoardViewModel {
    private(set) var activeQuests: [Quest] = []
    private(set) var completedQuests: [Quest] = []
    private(set) var failedQuests: [Quest] = []

    private let verificationService: QuestVerificationService
    private let aiService: VIGILAIService

    init(
        verificationService: QuestVerificationService = .shared,
        aiService: VIGILAIService = .shared
    ) {
        self.verificationService = verificationService
        self.aiService = aiService
    }

    /// Source data is usually driven by `@Query` from the view.
    func refresh(quests: [Quest]) {
        let sorted = quests.sorted { $0.assignedAt > $1.assignedAt }
        activeQuests = sorted.filter { $0.status == .active }
        completedQuests = sorted.filter { $0.status == .completed }
        failedQuests = sorted.filter { $0.status == .failed || $0.status == .expired }
    }

    func canSubmit(_ quest: Quest, modelContext: ModelContext) async -> Bool {
        await verificationService.isQuestVerifiable(quest, modelContext: modelContext)
    }

    func submitCompletion(quest: Quest, modelContext: ModelContext) async -> SubmissionOutcome {
        let verifiable = await verificationService.isQuestVerifiable(quest, modelContext: modelContext)
        guard verifiable else { return .verificationPending }

        guard let player = quest.player else {
            return .failed(message: "Player record missing.")
        }

        let context = makeAIContext(player: player)
        let verdict = await aiService.deliverVerdict(context: context)

        let success = verdict.verdictType != .punishment
        if success {
            quest.status = .completed
            applyXP(delta: quest.xpReward, to: player, stat: quest.statTarget)
            try? modelContext.save()
            return .success(message: "Submission accepted.")
        }

        quest.status = .failed
        let penalty = max(quest.xpPenalty, abs(verdict.xpDelta))
        applyXP(delta: -penalty, to: player, stat: quest.statTarget)
        try? modelContext.save()
        return .failed(message: "The system has rendered judgement.")
    }

    private func makeAIContext(player: Player) -> AIContext {
        let logs = player.dailyLogs.sorted { $0.date > $1.date }
        return AIContext(
            intelligence: player.intelligence,
            strength: player.strength,
            vitality: player.vitality,
            discipline: player.discipline,
            activeGoals: player.goals.filter(\.isActive).map {
                GoalSnapshot(
                    id: $0.id,
                    name: $0.name,
                    category: $0.category,
                    goalType: $0.goalType,
                    targetValue: $0.targetValue,
                    isCapGoal: $0.isCapGoal
                )
            },
            activeQuests: player.quests.filter { $0.status == .active }.map {
                QuestSnapshot(
                    id: $0.id,
                    title: $0.title,
                    questType: $0.questType,
                    status: $0.status,
                    deadline: $0.deadline,
                    statTarget: $0.statTarget
                )
            },
            last7DayLogs: Array(logs.prefix(7)).map {
                DayLogSnapshot(
                    date: $0.date,
                    disciplineScore: $0.disciplineScore,
                    totalXPEarned: $0.totalXPEarned,
                    totalXPLost: $0.totalXPLost,
                    isPerfectDay: $0.isPerfectDay,
                    didShowUp: $0.didShowUp,
                    phoneBlocksScheduled: $0.phoneBlocksScheduled,
                    phoneBlocksKept: $0.phoneBlocksKept
                )
            },
            streak: player.perfectDayStreak,
            rank: player.currentRank,
            titles: player.titles
        )
    }

    private func applyXP(delta: Int, to player: Player, stat: StatCategory) {
        guard delta != 0 else { return }
        switch stat {
        case .intelligence:
            var block = player.intelligence
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.intelligence = block
        case .strength:
            var block = player.strength
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.strength = block
        case .vitality:
            var block = player.vitality
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.vitality = block
        case .discipline:
            var block = player.discipline
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.discipline = block
        }
        player.totalXP = max(0, player.totalXP + delta)
    }
}

enum SubmissionOutcome {
    case success(message: String)
    case failed(message: String)
    case verificationPending
}
