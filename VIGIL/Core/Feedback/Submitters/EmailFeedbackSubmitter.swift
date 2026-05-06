import Foundation
import MessageUI
import UIKit

enum EmailFeedbackSubmitterError: Error {
    case mailUnavailable(String)
}

struct EmailFeedbackSubmitter: FeedbackSubmitting {
    let architectEmail: String

    init(architectEmail: String = Bundle.main.object(forInfoDictionaryKey: "ARCHITECT_EMAIL") as? String ?? "architect@vigil.app") {
        self.architectEmail = architectEmail
    }

    func submit(_ entry: FeedbackEntry, diagnostics: DiagnosticsBundle?) async throws {
        let subject = "[VIGIL] [\(entry.kind.rawValue.uppercased())] \(entry.title ?? String(entry.body.prefix(40)))"
        var body = entry.body
        if let title = entry.title, !title.isEmpty {
            body = "TITLE: \(title)\n\nBODY:\n\(entry.body)"
        }
        if entry.kind == .bug, let severity = entry.severity {
            body += "\n\nSEVERITY: \(severity)"
        }
        if entry.kind == .aiIssue, let output = entry.lastAIOutput {
            body += "\n\nLAST AI OUTPUT:\n\(output)"
        }
        if entry.includeDiagnostics, let diagnostics {
            body += "\n\nDIAGNOSTICS:\n\(diagnostics.formatForEmail())"
        }

        guard MFMailComposeViewController.canSendMail() else {
            UIPasteboard.general.string = "TO: \(architectEmail)\nSUBJECT: \(subject)\n\n\(body)"
            throw EmailFeedbackSubmitterError.mailUnavailable("Mail unavailable")
        }

        await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }
            let composer = MFMailComposeViewController()
            composer.setToRecipients([architectEmail])
            composer.setSubject(subject)
            composer.setMessageBody(body, isHTML: false)
            root.present(composer, animated: true)
        }
    }
}
