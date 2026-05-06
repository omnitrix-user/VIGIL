//
//  InterrogationView.swift
//  VIGIL
//

import SwiftUI

enum InterrogationKind {
    case name
    case building
    case weakness
    case seriousness
    case schedule
    case goalsPrompt
}

struct InterrogationView: View {
    let kind: InterrogationKind
    @Binding var textValue: String
    @Binding var multilineValue: String
    @Binding var sliderValue: Double
    @Binding var wakeTime: Date
    @Binding var sleepTime: Date
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            Text(question)
                .font(Font.vigil.titleLarge)
                .foregroundStyle(Color.text.primary)
                .fixedSize(horizontal: false, vertical: true)

            inputView

            Spacer()

            Button(action: onContinue) {
                Text("CONTINUE")
                    .font(Font.vigil.headline)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md.rawValue)
                    .background(isValid ? Color.accent.primary : Color.bg.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
    }

    @ViewBuilder
    private var inputView: some View {
        switch kind {
        case .name:
            TextField("Player ID", text: $textValue)
                .textInputAutocapitalization(.words)
                .padding(Spacing.md.rawValue)
                .background(Color.bg.secondary)
                .foregroundStyle(Color.text.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .building, .weakness, .goalsPrompt:
            TextField("Input", text: $multilineValue, axis: .vertical)
                .lineLimit(5...8)
                .padding(Spacing.md.rawValue)
                .background(Color.bg.secondary)
                .foregroundStyle(Color.text.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .seriousness:
            VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                Slider(value: $sliderValue, in: 1...10, step: 1)
                    .tint(Color.accent.primary)
                Text("Level \(Int(sliderValue))")
                    .font(Font.vigil.system)
                    .foregroundStyle(Color.text.secondary)
            }
            .padding(Spacing.md.rawValue)
            .background(Color.bg.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .schedule:
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                DatePicker("Day Start", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                DatePicker("Sleep", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .padding(Spacing.md.rawValue)
            .background(Color.bg.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .colorScheme(.dark)
        }
    }

    private var question: String {
        switch kind {
        case .name:
            return "State your name, player."
        case .building:
            return "What are you building or becoming?"
        case .weakness:
            return "What do you consistently fail to do?"
        case .seriousness:
            return "How serious are you? 1–10. The system will remember."
        case .schedule:
            return "When does your day start? When do you sleep?"
        case .goalsPrompt:
            return "Define your goals."
        }
    }

    private var isValid: Bool {
        switch kind {
        case .name:
            return !textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .building, .weakness, .goalsPrompt:
            return !multilineValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .seriousness:
            return true
        case .schedule:
            return true
        }
    }
}
