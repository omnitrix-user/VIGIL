//
//  QuestDetailView.swift
//  VIGIL
//

import SwiftData
import SwiftUI

struct QuestDetailView: View {
    let quest: Quest
    @Bindable var viewModel: QuestBoardViewModel

    @Environment(\.modelContext) private var modelContext

    @State private var isEvaluating = false
    @State private var canSubmit = true
    @State private var resultLine: String?
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                    badge
                    Text(quest.title.uppercased())
                        .font(Font.vigil.title)
                        .foregroundStyle(Color.text.primary)
                    Text(quest.questDescription)
                        .font(Font.vigil.system)
                        .foregroundStyle(Color.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    statRow("DEADLINE", value: deadlineText)
                    statRow("XP REWARD", value: "\(quest.xpReward)")
                    statRow("XP PENALTY", value: "\(quest.xpPenalty)")

                    if isEvaluating {
                        evaluatingView
                    }
                    if let resultLine {
                        Text(resultLine)
                            .font(Font.vigil.system)
                            .foregroundStyle(Color.text.primary)
                    }
                }
                .padding(Spacing.md.rawValue)
            }

            Button(action: submit) {
                Text("SUBMIT COMPLETION")
                    .font(Font.vigil.headline)
                    .tracking(2.2)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md.rawValue)
                    .background(canSubmit ? Color.accent.primary : Color.bg.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || isEvaluating)
            .padding(.horizontal, Spacing.md.rawValue)
            .padding(.bottom, Spacing.md.rawValue)
        }
        .background(Color.bg.primary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task {
            canSubmit = await viewModel.canSubmit(quest, modelContext: modelContext)
        }
    }

    private var badge: some View {
        Text(quest.questType.rawValue.uppercased())
            .font(Font.vigil.caption)
            .foregroundStyle(Color.text.primary)
            .padding(.horizontal, Spacing.sm.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(typeColor.opacity(0.25))
            .clipShape(Capsule())
    }

    private var evaluatingView: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "eye.fill")
                .foregroundStyle(Color.accent.primary)
                .opacity(pulse ? 0.25 : 1)
                .scaleEffect(pulse ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
            Text("The system is evaluating your submission...")
                .font(Font.vigil.system)
                .foregroundStyle(Color.text.secondary)
        }
        .onAppear { pulse = true }
        .onDisappear { pulse = false }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.vigil.caption)
                .foregroundStyle(Color.text.muted)
            Spacer()
            Text(value)
                .font(Font.vigil.body)
                .foregroundStyle(Color.text.primary)
        }
    }

    private func submit() {
        isEvaluating = true
        resultLine = nil
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            let outcome = await viewModel.submitCompletion(quest: quest, modelContext: modelContext)
            switch outcome {
            case .success:
                resultLine = "SUCCESS: QUEST COMPLETED."
            case .failed(let message):
                resultLine = message
            case .verificationPending:
                resultLine = "Verification pending."
            }
            isEvaluating = false
            canSubmit = await viewModel.canSubmit(quest, modelContext: modelContext)
        }
    }

    private var deadlineText: String {
        guard let deadline = quest.deadline else { return "None" }
        return deadline.formatted(date: .abbreviated, time: .shortened)
    }

    private var typeColor: Color {
        switch quest.questType {
        case .shadow: return Color.accent.secondary
        case .ascension: return Color.accent.gold
        case .reckoning: return Color.status.danger
        case .awakening: return Color.accent.primary
        }
    }
}
