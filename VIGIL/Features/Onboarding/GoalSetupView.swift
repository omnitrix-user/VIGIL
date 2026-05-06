//
//  GoalSetupView.swift
//  VIGIL
//

import SwiftUI

struct GoalSetupView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            Text("CASCADE ANALYSIS")
                .font(.vigil.titleLarge)
                .foregroundStyle(Color.accent.primary)

            TextField("IDENTIFY THE SOURCE", text: $coordinator.weaknessSource)
                .padding(Spacing.md.rawValue)
                .background(Color.bg.secondary)
                .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))

            Picker("FREQUENCY", selection: $coordinator.weaknessFrequency) {
                ForEach(["Multiple Times Per Day", "Daily", "Few Times Per Week", "Weekly", "Less Often"], id: \.self) {
                    Text($0.uppercased()).tag($0)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading) {
                Text("DURATION PER SESSION: \(Int(coordinator.weaknessDuration)) MIN")
                    .font(.vigil.system)
                Slider(value: $coordinator.weaknessDuration, in: 15...480, step: 5)
                    .tint(Color.accent.primary)
            }

            Picker("STATE YOUR VERDICT", selection: $coordinator.weaknessVerdict) {
                Text("LIMIT").tag(VerdictOption.limit)
                Text("ELIMINATE").tag(VerdictOption.eliminate)
                Text("REPLACE").tag(VerdictOption.replace)
                Text("TRACK ONLY").tag(VerdictOption.trackOnly)
            }
            .pickerStyle(.segmented)

            if coordinator.weaknessVerdict == .limit {
                VStack(alignment: .leading) {
                    Text("STATE THE CAP: \(Int(coordinator.weaknessCap)) MIN")
                        .font(.vigil.system)
                    Slider(value: $coordinator.weaknessCap, in: 15...480, step: 5)
                        .tint(Color.accent.primary)
                }
            }
            Spacer()
            VIGILButton(title: "CONTINUE", isDisabled: coordinator.weaknessSource.isEmpty, action: onContinue)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
    }
}
