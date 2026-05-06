//
//  InterrogationView.swift
//  VIGIL
//

import SwiftUI

struct InterrogationView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            BracketedText(value: "\(coordinator.queryIndex) / \(coordinator.totalQueries) SYSTEM QUERIES ANSWERED", color: .text.muted, font: .vigil.caption)
            Text("PHASE 1: IDENTITY")
                .font(.vigil.titleLarge)
                .foregroundStyle(Color.accent.primary)

            TextField("STATE YOUR DESIGNATION", text: $coordinator.username)
                .textInputAutocapitalization(.words)
                .padding(Spacing.md.rawValue)
                .background(Color.bg.secondary)
                .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))

            Stepper("AGE: \(coordinator.age)", value: $coordinator.age, in: 13...99)
                .font(.vigil.body)

            Picker("DESIGNATION TYPE", selection: $coordinator.designationType) {
                ForEach(["Male", "Female", "Other", "Prefer Not To Disclose"], id: \.self) { Text($0.uppercased()).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("CURRENT STATUS", selection: $coordinator.lifeStatus) {
                ForEach(["Student", "Working", "Job Hunting", "Self-Employed", "Other"], id: \.self) { Text($0.uppercased()).tag($0) }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                Text("IDENTIFY YOUR WEAKNESSES")
                    .font(.vigil.system)
                    .foregroundStyle(Color.text.secondary)
                ForEach(["Procrastination", "Distraction", "Laziness", "Anxiety", "Poor Sleep", "Addiction", "Lack Of Focus", "Other"], id: \.self) { item in
                    Button {
                        if coordinator.selectedWeaknesses.contains(item) {
                            coordinator.selectedWeaknesses.remove(item)
                        } else {
                            coordinator.selectedWeaknesses.insert(item)
                        }
                    } label: {
                        Text("[\(item.uppercased())]")
                            .font(.vigil.caption)
                            .foregroundStyle(coordinator.selectedWeaknesses.contains(item) ? Color.bg.primary : Color.text.secondary)
                            .padding(.horizontal, Spacing.sm.rawValue)
                            .padding(.vertical, Spacing.xs.rawValue)
                            .background(coordinator.selectedWeaknesses.contains(item) ? Color.accent.primary : Color.bg.tertiary)
                            .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
            VIGILButton(title: "CONTINUE", isDisabled: !isValid, action: onContinue)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
    }

    private var isValid: Bool {
        !coordinator.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !coordinator.selectedWeaknesses.isEmpty
    }
}
