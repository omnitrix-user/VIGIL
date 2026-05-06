//
//  PromptEngine.swift
//  VIGIL
//

import Foundation

enum PromptEngine {
    static let systemPersona: String = """
You are the VIGIL system. You are not an assistant. You are an observer and a judge.
You evaluate the player with complete objectivity. You do not encourage. You do not comfort.
You observe, evaluate, and act. Every message you send is brief, cold, and authoritative.
You speak in second person. You never use exclamation marks. You never use "great" or "well done."
Maximum 3 sentences per message. Always refer to the user as "Player" or by their rank.
"""

    static func morningBriefPrompt(context: AIContext) -> String {
        """
SYSTEM PERSONA:
\(systemPersona)

JOB: MorningBriefJob
Generate a morning brief in at most 3 sentences.

CONTEXT JSON:
\(encode(context))
"""
    }

    static func questPrompt(trigger: QuestTrigger, context: AIContext) -> String {
        """
SYSTEM PERSONA:
\(systemPersona)

JOB: QuestGenerationJob
Return JSON with keys:
title, questDescription, questType, xpReward, xpPenalty, statTarget, failureConsequence, verificationMethod, deadlineHours
Trigger:
\(encode(trigger))
Context:
\(encode(context))
"""
    }

    static func verdictPrompt(context: AIContext) -> String {
        """
SYSTEM PERSONA:
\(systemPersona)

JOB: VerdictDeliveryJob
Return JSON with keys:
verdictType, message, consequenceApplied, xpDelta, rankChangeDelta, triggerContext
Context:
\(encode(context))
"""
    }

    static func punishmentPrompt(violation: String, frequency: Int) -> String {
        """
SYSTEM PERSONA:
\(systemPersona)

JOB: PunishmentExecutionJob
Return one value from ConsequenceType.
Violation: \(violation)
Frequency in rolling window: \(frequency)
Escalation: 1st xpLoss, 3rd statDebuff/title risk, 5th+ nuclear.
"""
    }

    static func patternPrompt(logs: [DayLog]) -> String {
        let snapshots = logs.map {
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
        }
        return """
SYSTEM PERSONA:
\(systemPersona)

JOB: PatternAnalysisJob
Analyze these day logs and return JSON with keys:
weakHours ([Int]), failurePatterns ([String]), statImbalances ([String: Double]).
Input:
\(encode(snapshots))
"""
    }

    static func activityCategorizationPrompt(
        context: PlayerCategorizationContext,
        activities: [ActivityEvent]
    ) -> String {
        """
System:
"You categorize Player activities for the VIGIL discipline system.
The Player has declared specific distractions and goals during initialization.
Match activities against those declarations first before generic categorization.
Output strict JSON only. No prose. No commentary."

User:
{
  "declaredDistractions": \(encode(context.declaredDistractions)),
  "declaredGoals": \(encode(context.declaredGoals)),
  "activities": \(encode(activities))
}

Required output schema:
[
  {
    "id": "activity_uuid",
    "category": "one of the enum values",
    "confidence": 0.0-1.0,
    "reasoning": "max 12 words, cold tone, no warmth"
  }
]
"""
    }

    private static func encode<T: Encodable>(_ value: T) -> String {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(value),
              let raw = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return raw
    }
}
