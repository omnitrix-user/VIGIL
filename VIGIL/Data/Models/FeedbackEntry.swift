import Foundation
import SwiftData

@Model
final class FeedbackEntry {
    var id: UUID
    var kindRaw: String
    var title: String?
    var body: String
    var severity: Int?
    var lastAIOutput: String?
    var includeDiagnostics: Bool
    var createdAt: Date
    var submitted: Bool

    init(
        id: UUID = UUID(),
        kind: FeedbackKind,
        title: String? = nil,
        body: String,
        severity: Int? = nil,
        lastAIOutput: String? = nil,
        includeDiagnostics: Bool = false,
        createdAt: Date = Date(),
        submitted: Bool = false
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.title = title
        self.body = body
        self.severity = severity
        self.lastAIOutput = lastAIOutput
        self.includeDiagnostics = includeDiagnostics
        self.createdAt = createdAt
        self.submitted = submitted
    }

    var kind: FeedbackKind {
        get { FeedbackKind(rawValue: kindRaw) ?? .insight }
        set { kindRaw = newValue.rawValue }
    }
}
