import Foundation

enum OnboardingStep: String, CaseIterable, Codable {
    case scan
    case identity
    case weaknessCascade
    case profileFragmentOne
    case intelligence
    case profileFragmentTwo
    case strength
    case profileFragmentThree
    case vitality
    case profileFragmentFour
    case dailyGoalConfirmation
    case permissions
    case contract
}
