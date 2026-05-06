//
//  VIGILAIService.swift
//  VIGIL
//

import Foundation
import Observation
#if canImport(FoundationModels)
import FoundationModels
#endif

@Observable
@MainActor
final class VIGILAIService {
    static let shared = VIGILAIService()

    private struct QueuedJob: Codable, Sendable {
        enum Kind: String, Codable, Sendable {
            case morningBrief
            case quest
            case verdict
            case punishment
            case pattern
        }
        let id: UUID
        let kind: Kind
        let payload: String
        let createdAt: Date
    }

    private let queueKey = "vigil.ai.jobs.queue.v1"
    private(set) var queuedJobsCount = 0

    private init() {
        queuedJobsCount = loadQueue().count
    }

    func runMorningBrief(context: AIContext) async -> String {
        let prompt = PromptEngine.morningBriefPrompt(context: context)
        guard canUseFoundationModels else {
            enqueue(kind: .morningBrief, payload: prompt)
            return fallbackEvaluatingLine
        }
        return await modelText(prompt: prompt, fallback: fallbackNotedLine)
    }

    func generateQuest(trigger: QuestTrigger) async -> Quest {
        let context = AIContext(
            intellect: .init(currentXP: 0, totalXP: 0, level: 1, xpToNextLevel: 0, debuffActive: false, debuffExpiresAt: nil, weekHistory: []),
            strength: .init(currentXP: 0, totalXP: 0, level: 1, xpToNextLevel: 0, debuffActive: false, debuffExpiresAt: nil, weekHistory: []),
            spirit: .init(currentXP: 0, totalXP: 0, level: 1, xpToNextLevel: 0, debuffActive: false, debuffExpiresAt: nil, weekHistory: []),
            discipline: .init(currentXP: 0, totalXP: 0, level: 1, xpToNextLevel: 0, debuffActive: false, debuffExpiresAt: nil, weekHistory: []),
            activeGoals: [],
            activeQuests: [],
            last7DayLogs: [],
            streak: 0,
            rank: .E,
            titles: []
        )
        let prompt = PromptEngine.questPrompt(trigger: trigger, context: context)
        guard canUseFoundationModels else {
            enqueue(kind: .quest, payload: prompt)
            return fallbackQuest(trigger: trigger)
        }

        let raw = await modelText(prompt: prompt, fallback: "")
        return parseQuest(raw: raw, trigger: trigger) ?? fallbackQuest(trigger: trigger)
    }

    func deliverVerdict(context: AIContext) async -> AIVerdict {
        let prompt = PromptEngine.verdictPrompt(context: context)
        guard canUseFoundationModels else {
            enqueue(kind: .verdict, payload: prompt)
            return fallbackVerdict(message: fallbackJudgementLine)
        }

        let raw = await modelText(prompt: prompt, fallback: "")
        return parseVerdict(raw: raw) ?? fallbackVerdict(message: fallbackNotedLine)
    }

    func decidePunishment(violation: ViolationType, frequency: Int) async -> ConsequenceType {
        let prompt = PromptEngine.punishmentPrompt(violation: violation.rawValue, frequency: frequency)
        guard canUseFoundationModels else {
            enqueue(kind: .punishment, payload: prompt)
            return fallbackPunishment(for: frequency)
        }
        let raw = await modelText(prompt: prompt, fallback: "")
        return parseConsequence(raw: raw) ?? fallbackPunishment(for: frequency)
    }

    func analysePatterns(logs: [DayLog]) async -> PatternInsight {
        let prompt = PromptEngine.patternPrompt(logs: logs)
        guard canUseFoundationModels else {
            enqueue(kind: .pattern, payload: prompt)
            return fallbackPatternInsight(from: logs)
        }

        let raw = await modelText(prompt: prompt, fallback: "")
        return parsePattern(raw: raw) ?? fallbackPatternInsight(from: logs)
    }

    func parseGoalDraft(from naturalLanguage: String) async -> GoalDraft {
        let lower = naturalLanguage.lowercased()
        let isCap = lower.contains("limit") || lower.contains("max") || lower.contains("no more than")
        let numeric = Self.extractFirstNumber(from: lower) ?? 30
        let unit = lower.contains("hour") ? "minutes" : (lower.contains("session") ? "sessions" : "minutes")
        let value = lower.contains("hour") ? numeric * 60 : numeric

        let category: StatCategory
        if lower.contains("workout") || lower.contains("run") || lower.contains("gym") {
            category = .strength
        } else if lower.contains("meditat") || lower.contains("sleep") {
            category = .spirit
        } else if lower.contains("phone") || lower.contains("social") || lower.contains("pool") {
            category = .discipline
        } else {
            category = .intellect
        }

        return GoalDraft(
            name: naturalLanguage.capitalized,
            category: category,
            goalType: unit == "sessions" ? .count : .duration,
            targetValue: value,
            unit: unit,
            isCapGoal: isCap,
            xpPerUnit: unit == "sessions" ? 20 : 1,
            xpPenaltyPerUnit: isCap ? 2 : 0,
            icon: category == .discipline ? "hand.raised.fill" : "target",
            colorHex: "#6C63FF"
        )
    }

    func retryQueuedJobsIfAvailable() async {
        guard canUseFoundationModels else { return }
        var queue = loadQueue()
        guard !queue.isEmpty else { return }

        var unresolved: [QueuedJob] = []
        for item in queue {
            let result = await modelText(prompt: item.payload, fallback: "")
            if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                unresolved.append(item)
            }
        }
        queue = unresolved
        saveQueue(queue)
        queuedJobsCount = queue.count
    }

    private var canUseFoundationModels: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 18.1, *) {
            #if canImport(FoundationModels)
            return true
            #else
            return false
            #endif
        }
        return false
        #endif
    }

    private func modelText(prompt: String, fallback: String) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 18.1, *) {
            // FoundationModels integration point (real device w/ Apple Intelligence enabled).
            // Keep prompt composition centralized in PromptEngine.
            // TODO: Replace stub with concrete FoundationModels session call when model entitlement/config is finalized.
            _ = prompt
            return fallback.isEmpty ? fallbackNotedLine : fallback
        }
        #endif
        return fallback.isEmpty ? fallbackEvaluatingLine : fallback
    }

    private func enqueue(kind: QueuedJob.Kind, payload: String) {
        var queue = loadQueue()
        queue.append(
            QueuedJob(id: UUID(), kind: kind, payload: payload, createdAt: Date())
        )
        saveQueue(queue)
        queuedJobsCount = queue.count
    }

    private func loadQueue() -> [QueuedJob] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let decoded = try? JSONDecoder().decode([QueuedJob].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveQueue(_ queue: [QueuedJob]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }

    private func parseQuest(raw: String, trigger: QuestTrigger) -> Quest? {
        guard let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(QuestPayload.self, from: data) else {
            return nil
        }
        return Quest(
            title: payload.title,
            questDescription: payload.questDescription,
            questType: payload.questType,
            assignedAt: Date(),
            deadline: payload.deadlineHours.map { Date().addingTimeInterval(Double($0) * 3600) },
            xpReward: payload.xpReward,
            xpPenalty: payload.xpPenalty,
            statTarget: payload.statTarget,
            status: .active,
            failureConsequence: payload.failureConsequence,
            isReactive: trigger.type == .reckoning,
            triggerPattern: trigger.pattern,
            verificationMethod: payload.verificationMethod
        )
    }

    private func parseVerdict(raw: String) -> AIVerdict? {
        guard let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(VerdictPayload.self, from: data) else {
            return nil
        }
        return AIVerdict(
            deliveredAt: Date(),
            verdictType: payload.verdictType,
            message: payload.message,
            consequenceApplied: payload.consequenceApplied,
            xpDelta: payload.xpDelta,
            rankChangeDelta: payload.rankChangeDelta,
            triggerContext: payload.triggerContext
        )
    }

    private func parseConsequence(raw: String) -> ConsequenceType? {
        let clean = raw.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return ConsequenceType(rawValue: clean)
    }

    private func parsePattern(raw: String) -> PatternInsight? {
        guard let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(PatternInsight.self, from: data) else {
            return nil
        }
        return payload
    }

    private func fallbackQuest(trigger: QuestTrigger) -> Quest {
        Quest(
            title: "System Assignment",
            questDescription: fallbackEvaluatingLine,
            questType: trigger.type.asQuestType,
            assignedAt: Date(),
            deadline: Date().addingTimeInterval(8 * 3600),
            xpReward: max(40, trigger.severity * 25),
            xpPenalty: max(20, trigger.severity * 20),
            statTarget: trigger.statTarget,
            status: .active,
            failureConsequence: .xpLoss,
            isReactive: trigger.type == .reckoning,
            triggerPattern: trigger.pattern,
            verificationMethod: .manual
        )
    }

    private func fallbackVerdict(message: String) -> AIVerdict {
        AIVerdict(
            deliveredAt: Date(),
            verdictType: .observation,
            message: message,
            consequenceApplied: nil,
            xpDelta: 0,
            rankChangeDelta: 0,
            triggerContext: "fallback"
        )
    }

    private func fallbackPatternInsight(from logs: [DayLog]) -> PatternInsight {
        let weakHours = [9, 14, 21]
        let failurePatterns = logs.filter { !$0.isPerfectDay }.prefix(3).map { _ in "Consistency drop detected" }
        let statImbalances: [String: Double] = [
            StatCategory.intellect.rawValue: 0.25,
            StatCategory.strength.rawValue: 0.25,
            StatCategory.spirit.rawValue: 0.2,
            StatCategory.discipline.rawValue: 0.3,
        ]
        return PatternInsight(weakHours: weakHours, failurePatterns: failurePatterns, statImbalances: statImbalances)
    }

    private func fallbackPunishment(for frequency: Int) -> ConsequenceType {
        if frequency >= 5 { return .nuclear }
        if frequency >= 3 { return .statDebuff }
        return .xpLoss
    }

    private static func extractFirstNumber(from text: String) -> Double? {
        let parts = text.split { !$0.isNumber && $0 != "." }
        guard let token = parts.first else { return nil }
        return Double(token)
    }

    private let fallbackEvaluatingLine = "The system is evaluating. Stand by."
    private let fallbackNotedLine = "Player. Your performance has been noted."
    private let fallbackJudgementLine = "The system has rendered judgement."
}

private struct QuestPayload: Codable {
    var title: String
    var questDescription: String
    var questType: QuestType
    var xpReward: Int
    var xpPenalty: Int
    var statTarget: StatCategory
    var failureConsequence: ConsequenceType
    var verificationMethod: VerificationMethod
    var deadlineHours: Int?
}

private struct VerdictPayload: Codable {
    var verdictType: VerdictType
    var message: String
    var consequenceApplied: ConsequenceType?
    var xpDelta: Int
    var rankChangeDelta: Int
    var triggerContext: String
}

private extension QuestTrigger.TriggerType {
    var asQuestType: QuestType {
        switch self {
        case .shadow: return .shadow
        case .ascension: return .ascension
        case .reckoning: return .reckoning
        }
    }
}
