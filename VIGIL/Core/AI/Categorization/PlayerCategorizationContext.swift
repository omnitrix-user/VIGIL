import Foundation

struct DeclaredDistraction: Codable, Sendable {
    let name: String
    let frequency: String
    let verdict: VerdictOption
    let capValue: Double?
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
