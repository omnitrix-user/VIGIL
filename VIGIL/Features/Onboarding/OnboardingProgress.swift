import Foundation
import SwiftData

@Model
final class OnboardingProgress {
    var id: UUID
    var currentStep: String
    var currentQueryIndex: Int
    var totalQueries: Int
    var payloadJSON: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        currentStep: String = OnboardingStep.scan.rawValue,
        currentQueryIndex: Int = 1,
        totalQueries: Int = 40,
        payloadJSON: String = "{}",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.currentStep = currentStep
        self.currentQueryIndex = currentQueryIndex
        self.totalQueries = totalQueries
        self.payloadJSON = payloadJSON
        self.updatedAt = updatedAt
    }
}
