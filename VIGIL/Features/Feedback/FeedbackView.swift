import SwiftData
import SwiftUI

struct FeedbackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIVerdict.deliveredAt, order: .reverse) private var verdicts: [AIVerdict]

    @State private var mode = 0 // 0 structured, 1 raw
    @State private var kind: FeedbackKind = .bug
    @State private var title = ""
    @State private var bodyText = ""
    @State private var severity = 3.0
    @State private var includeDiagnostics = true
    @State private var lastAIOutput = ""
    @State private var confirmationMessage = ""

    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Picker("", selection: $mode) {
                Text("STRUCTURED").tag(0)
                Text("RAW").tag(1)
            }
            .pickerStyle(.segmented)

            if mode == 0 {
                Picker("", selection: $kind) {
                    Text("BUG").tag(FeedbackKind.bug)
                    Text("FEATURE").tag(FeedbackKind.featureRequest)
                    Text("AI ISSUE").tag(FeedbackKind.aiIssue)
                    Text("INSIGHT").tag(FeedbackKind.insight)
                }
                .pickerStyle(.segmented)

                TextField("TITLE", text: $title)
                    .padding()
                    .background(Color.bg.secondary)
                    .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))

                TextField("DESCRIPTION", text: $bodyText, axis: .vertical)
                    .lineLimit(6...12)
                    .padding()
                    .background(Color.bg.secondary)
                    .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))

                if kind == .bug {
                    VStack(alignment: .leading) {
                        Text("SEVERITY: \(Int(severity))").font(.vigil.system)
                        Slider(value: $severity, in: 1...5, step: 1).tint(Color.status.danger)
                    }
                }
                if kind == .aiIssue {
                    TextField("LAST AI OUTPUT", text: $lastAIOutput, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color.bg.secondary)
                        .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                        .onAppear { if lastAIOutput.isEmpty { lastAIOutput = verdicts.first?.message ?? "" } }
                }

                Toggle("[INCLUDE SYSTEM DIAGNOSTICS]", isOn: $includeDiagnostics)
                    .font(.vigil.caption)
            } else {
                TextField("Send signal to architect...", text: $bodyText, axis: .vertical)
                    .lineLimit(8...14)
                    .padding()
                    .background(Color.bg.secondary)
                    .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
            }

            VIGILButton(title: "SUBMIT") {
                Task { await submit() }
            }
            if !confirmationMessage.isEmpty {
                Text(confirmationMessage.uppercased())
                    .font(.vigil.system)
                    .foregroundStyle(Color.text.secondary)
            }
        }
        .padding()
        .background(Color.bg.primary.ignoresSafeArea())
    }

    @MainActor
    private func submit() async {
        guard !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            confirmationMessage = "The system received nothing. Try again."
            return
        }
        let effectiveKind: FeedbackKind = mode == 1 ? .rant : kind
        let entry = FeedbackEntry(
            kind: effectiveKind,
            title: mode == 1 ? nil : title,
            body: bodyText,
            severity: effectiveKind == .bug ? Int(severity) : nil,
            lastAIOutput: effectiveKind == .aiIssue ? lastAIOutput : nil,
            includeDiagnostics: mode == 1 ? false : includeDiagnostics
        )
        do {
            try await FeedbackService.shared.submit(entry, modelContext: modelContext)
            confirmationMessage = "Signal received. The architect has been notified."
            title = ""
            bodyText = ""
        } catch EmailFeedbackSubmitterError.mailUnavailable {
            confirmationMessage = """
[REPORT QUEUED]
Mail unavailable on this device.
Report copied to clipboard.
Send to architect@vigil.app manually.
"""
        } catch {
            confirmationMessage = "Transmission failed. Report saved locally."
        }
    }
}
