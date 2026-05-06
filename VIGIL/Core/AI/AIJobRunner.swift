//
//  AIJobRunner.swift
//  VIGIL
//

import Foundation
import Observation
import SwiftData

@Observable
final class AIJobRunner {
    static let shared = AIJobRunner()

    private(set) var lastMorningBriefAt: Date?
    private(set) var lastPatternAnalysisAt: Date?
    private(set) var isMonitoringVerdictTriggers = false

    private let service: VIGILAIService
    private let worker = AIBackgroundWorker()
    private var morningTimer: Timer?

    init(service: VIGILAIService = .shared) {
        self.service = service
    }

    func scheduleMorningBrief(for player: Player) {
        morningTimer?.invalidate()
        let next = nextOccurrence(of: player.wakeTime)
        let interval = max(1, next.timeIntervalSinceNow)
        morningTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.runMorningBriefJob(for: player)
                self.scheduleMorningBrief(for: player)
            }
        }
    }

    func startVerdictMonitoring() {
        isMonitoringVerdictTriggers = true
    }

    func stopVerdictMonitoring() {
        isMonitoringVerdictTriggers = false
    }

    func runMorningBriefJob(for player: Player) async {
        await worker.run {
            let context = AIContext.from(player: player)
            _ = await self.service.runMorningBrief(context: context)
            await self.service.retryQueuedJobsIfAvailable()
        }
        lastMorningBriefAt = Date()
    }

    func evaluateVerdictTriggers(player: Player, recentLogs: [DayLog], modelContext: ModelContext) async {
        guard isMonitoringVerdictTriggers else { return }
        await worker.run {
            guard Self.shouldTriggerVerdict(player: player, logs: recentLogs) else { return }
            let context = AIContext.from(player: player)
            let verdict = await self.service.deliverVerdict(context: context)
            verdict.player = player
            modelContext.insert(verdict)
            try? modelContext.save()
        }
    }

    func runPatternAnalysisDaily(player: Player, logs: [DayLog]) async -> PatternInsight {
        let insight = await worker.runAndReturn {
            let latest30 = Array(logs.sorted { $0.date > $1.date }.prefix(30))
            let result = await self.service.analysePatterns(logs: latest30)
            await self.service.retryQueuedJobsIfAvailable()
            return result
        }
        lastPatternAnalysisAt = Date()
        _ = player
        return insight
    }

    private func nextOccurrence(of timeSource: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: timeSource)
        let now = Date()
        var next = cal.date(bySettingHour: comps.hour ?? 6, minute: comps.minute ?? 0, second: 0, of: now) ?? now
        if next <= now {
            next = cal.date(byAdding: .day, value: 1, to: next) ?? now.addingTimeInterval(86400)
        }
        return next
    }

    private static func shouldTriggerVerdict(player: Player, logs: [DayLog]) -> Bool {
        if player.perfectDayStreak > 0, player.perfectDayStreak % 7 == 0 {
            return true
        }
        let recent = logs.sorted { $0.date > $1.date }.prefix(3)
        let consecutiveFailures = recent.filter { !$0.isPerfectDay }.count
        return consecutiveFailures >= 3
    }
}

actor AIBackgroundWorker {
    func run(_ operation: @escaping @Sendable () async -> Void) async {
        await operation()
    }

    func runAndReturn<T: Sendable>(_ operation: @escaping @Sendable () async -> T) async -> T {
        await operation()
    }
}

private extension AIContext {
    static func from(player: Player) -> AIContext {
        let sortedLogs = player.dailyLogs.sorted { $0.date > $1.date }
        return AIContext(
            intellect: player.intellect,
            strength: player.strength,
            spirit: player.spirit,
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
            last7DayLogs: Array(sortedLogs.prefix(7)).map {
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
}
