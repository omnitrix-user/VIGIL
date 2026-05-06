//
//  GoalSetupView.swift
//  VIGIL
//

import SwiftUI

struct GoalSetupView: View {
    @Binding var drafts: [GoalDraft]
    let onContinue: () -> Void

    @State private var input = ""
    @State private var isParsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            Text("Define your goals.")
                .font(Font.vigil.titleLarge)
                .foregroundStyle(Color.text.primary)

            TextField("I want to limit pool to 1 hour", text: $input)
                .padding(Spacing.md.rawValue)
                .background(Color.bg.secondary)
                .foregroundStyle(Color.text.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: parseAndAdd) {
                Text(isParsing ? "PARSING..." : "ADD GOAL")
                    .font(Font.vigil.headline)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm.rawValue)
                    .background(Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isParsing)

            ScrollView {
                VStack(spacing: Spacing.sm.rawValue) {
                    ForEach(drafts) { draft in
                        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                            Text(draft.name.uppercased())
                                .font(Font.vigil.headline)
                                .foregroundStyle(Color.text.primary)
                            Text("\(draft.goalType.rawValue.uppercased()) • \(Int(draft.targetValue)) \(draft.unit)")
                                .font(Font.vigil.body)
                                .foregroundStyle(Color.text.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md.rawValue)
                        .background(Color.bg.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

            Button(action: onContinue) {
                Text("CONTINUE")
                    .font(Font.vigil.headline)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md.rawValue)
                    .background(drafts.isEmpty ? Color.bg.tertiary : Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(drafts.isEmpty)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
    }

    private func parseAndAdd() {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        isParsing = true
        Task {
            let parsed = await VIGILAIService.shared.parseGoalDraft(from: raw)
            drafts.append(parsed)
            input = ""
            isParsing = false
        }
    }
}
