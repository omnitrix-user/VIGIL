import Foundation

struct FoundationModelsCategorizer: ActivityCategorizing {
    func categorize(
        _ batch: [ActivityEvent],
        playerContext: PlayerCategorizationContext
    ) async throws -> [CategorizedActivity] {
        let chunks = stride(from: 0, to: batch.count, by: 20).map {
            Array(batch[$0..<min($0 + 20, batch.count)])
        }
        var collected: [CategorizedActivity] = []
        for chunk in chunks {
            let prompt = PromptEngine.activityCategorizationPrompt(
                context: playerContext,
                activities: chunk
            )
            let raw = await VIGILAIService.shared.modelJSON(prompt: prompt)
            let parsed = decode(raw: raw, fallback: chunk)
            collected.append(contentsOf: parsed)
        }
        return collected
    }

    private func decode(raw: String, fallback: [ActivityEvent]) -> [CategorizedActivity] {
        guard let data = raw.data(using: .utf8),
              let rows = try? JSONDecoder().decode([ResponseRow].self, from: data) else {
            return fallback.map {
                CategorizedActivity(activityId: $0.id, category: .unknown, confidence: 0.5, reasoning: "Categorization unavailable")
            }
        }
        return rows.map { row in
            CategorizedActivity(
                activityId: row.id,
                category: ActivityCategory(rawValue: row.category) ?? .unknown,
                confidence: row.confidence,
                reasoning: row.reasoning
            )
        }
    }
}

private struct ResponseRow: Codable {
    let id: UUID
    let category: String
    let confidence: Double
    let reasoning: String
}
