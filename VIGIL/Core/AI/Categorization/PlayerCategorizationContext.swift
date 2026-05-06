import Foundation

struct DeclaredDistraction: Codable, Sendable {
    let name: String
    let source: String
    let frequency: String
    let durationMinutes: Double
    let verdict: VerdictOption
    let capValue: Double?

    init(
        name: String,
        source: String = "",
        frequency: String,
        durationMinutes: Double = 60,
        verdict: VerdictOption,
        capValue: Double?
    ) {
        self.name = name
        self.source = source
        self.frequency = frequency
        self.durationMinutes = durationMinutes
        self.verdict = verdict
        self.capValue = capValue
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case source
        case frequency
        case durationMinutes
        case verdict
        case capValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
        frequency = try container.decode(String.self, forKey: .frequency)
        durationMinutes = try container.decodeIfPresent(Double.self, forKey: .durationMinutes) ?? 60
        verdict = try container.decode(VerdictOption.self, forKey: .verdict)
        capValue = try container.decodeIfPresent(Double.self, forKey: .capValue)
    }
}

struct DeclaredGoal: Codable, Sendable {
    let name: String
    let category: StatCategory
    let targetValue: Double
}

struct PlayerCategorizationContext: Codable, Sendable {
    let declaredDistractions: [DeclaredDistraction]
    let declaredGoals: [DeclaredGoal]
    let lifeSituation: String
    let primaryFieldOfFocus: String
}
