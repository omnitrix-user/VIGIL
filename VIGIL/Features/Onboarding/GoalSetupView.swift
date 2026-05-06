//
//  GoalSetupView.swift
//  VIGIL
//

import SwiftUI

struct GoalSetupView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    @State private var validationMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            Text("CASCADE ANALYSIS")
                .font(.vigil.titleLarge)
                .foregroundStyle(Color.accent.primary)

            Text(coordinator.weaknessCascade.progressHeader)
                .font(.vigil.system)
                .foregroundStyle(Color.text.secondary)

            Text("WEAKNESS: [\(coordinator.weaknessCascade.currentWeakness?.rawValue.uppercased() ?? "UNKNOWN")]")
                .font(.vigil.system)
                .foregroundStyle(Color.accent.secondary)

            switch coordinator.weaknessCascade.phase {
            case .source:
                TextField("IDENTIFY THE SOURCE", text: sourceBinding)
                    .padding(Spacing.md.rawValue)
                    .background(Color.bg.secondary)
                    .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
            case .frequency:
                Picker("FREQUENCY", selection: frequencyBinding) {
                    ForEach(["Multiple Times Per Day", "Daily", "Few Times Per Week", "Weekly", "Less Often"], id: \.self) {
                        Text($0.uppercased()).tag($0)
                    }
                }
                .pickerStyle(.segmented)
            case .duration:
                VStack(alignment: .leading) {
                    Text("DURATION PER SESSION: \(Int(durationBinding.wrappedValue)) MIN")
                        .font(.vigil.system)
                    Slider(value: durationBinding, in: 15...480, step: 5)
                        .tint(Color.accent.primary)
                }
            case .verdict:
                Picker("STATE YOUR VERDICT", selection: verdictBinding) {
                    Text("LIMIT").tag(VerdictOption.limit)
                    Text("ELIMINATE").tag(VerdictOption.eliminate)
                    Text("REPLACE").tag(VerdictOption.replace)
                    Text("TRACK ONLY").tag(VerdictOption.trackOnly)
                }
                .pickerStyle(.segmented)
            case .cap:
                VStack(alignment: .leading) {
                    Text("STATE THE CAP: \(Int(capBinding.wrappedValue)) MIN")
                        .font(.vigil.system)
                    Slider(value: capBinding, in: 15...480, step: 5)
                        .tint(Color.accent.primary)
                }
            }
            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(.vigil.system)
                    .foregroundStyle(Color.status.warning)
            }
            Spacer()
            HStack(spacing: Spacing.sm.rawValue) {
                if coordinator.weaknessCascade.currentIndex > 0 || coordinator.weaknessCascade.phase != .source {
                    VIGILButton(title: "BACK", fill: .bg.tertiary, foreground: .text.secondary) {
                        coordinator.goToPreviousWeaknessStep()
                    }
                }
                VIGILButton(title: coordinator.weaknessCascade.currentIndex == coordinator.weaknessCascade.weaknesses.count - 1 && coordinator.weaknessCascade.phase == .cap ? "FINALIZE WEAKNESS DECLARATIONS" : "CONTINUE") {
                    guard coordinator.canContinueWeaknessCascade() else {
                        validationMessage = "[SYSTEM REQUIRES COMPLETION OF CURRENT WEAKNESS DECLARATION]"
                        return
                    }
                    validationMessage = ""
                    onContinue()
                }
            }
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
    }

    private var sourceBinding: Binding<String> {
        Binding(
            get: { coordinator.weaknessCascade.inProgress?.source ?? "" },
            set: { value in coordinator.updateCurrentWeakness { $0.source = value } }
        )
    }

    private var frequencyBinding: Binding<String> {
        Binding(
            get: { coordinator.weaknessCascade.inProgress?.frequency ?? "Daily" },
            set: { value in coordinator.updateCurrentWeakness { $0.frequency = value } }
        )
    }

    private var durationBinding: Binding<Double> {
        Binding(
            get: { coordinator.weaknessCascade.inProgress?.durationMinutes ?? 60 },
            set: { value in coordinator.updateCurrentWeakness { $0.durationMinutes = value } }
        )
    }

    private var verdictBinding: Binding<VerdictOption> {
        Binding(
            get: { coordinator.weaknessCascade.inProgress?.verdict ?? .trackOnly },
            set: { value in coordinator.updateCurrentWeakness { $0.verdict = value } }
        )
    }

    private var capBinding: Binding<Double> {
        Binding(
            get: { coordinator.weaknessCascade.inProgress?.capValue ?? 60 },
            set: { value in coordinator.updateCurrentWeakness { $0.capValue = value } }
        )
    }
}
