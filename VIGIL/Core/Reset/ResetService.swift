import Foundation
import SwiftData

@MainActor
final class ResetService {
    static let shared = ResetService()

    private init() {}

    func clearTours(modelContext: ModelContext) {
        let rows = (try? modelContext.fetch(FetchDescriptor<TourState>())) ?? []
        rows.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }

    func clearFeedback(modelContext: ModelContext) {
        let rows = (try? modelContext.fetch(FetchDescriptor<FeedbackEntry>())) ?? []
        rows.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}
