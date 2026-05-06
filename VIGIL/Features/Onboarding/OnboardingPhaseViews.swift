import SwiftUI

struct FragmentView: View {
    let step: OnboardingStep
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            Text("PROFILE FRAGMENT")
                .font(.vigil.titleLarge)
                .foregroundStyle(Color.accent.primary)
            Text(fragmentText)
                .font(.vigil.system)
                .foregroundStyle(Color.text.secondary)
                .padding()
                .background(Color.bg.secondary)
                .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                .overlay(ScanlineOverlay())
            VIGILButton(title: "CONTINUE", action: onContinue)
        }
        .padding()
    }

    private var fragmentText: String {
        switch step {
        case .profileFragmentOne: return "IDENTITY BASELINE RECORDED."
        case .profileFragmentTwo: return "INTELLIGENCE DOMAIN MAPPED."
        case .profileFragmentThree: return "STRENGTH DOMAIN MAPPED."
        case .profileFragmentFour: return "VITALITY DOMAIN MAPPED."
        default: return "PROFILE SEGMENT RECORDED."
        }
    }
}

struct IntelligenceView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Text("PHASE 2: INTELLIGENCE").font(.vigil.titleLarge).foregroundStyle(Color.accent.primary)
            TextField("FIELD OF FOCUS", text: $coordinator.fieldOfFocus).padding().background(Color.bg.secondary).overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
            TextField("SPECIFIC OBJECTIVE", text: $coordinator.specificObjective).padding().background(Color.bg.secondary).overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
            Picker("TARGET COMPLETION", selection: $coordinator.targetCompletion) { ForEach(["1mo", "3mo", "6mo", "1yr", "2yr+"], id: \.self) { Text($0.uppercased()).tag($0) } }.pickerStyle(.segmented)
            Text("CURRENT DAILY INVESTMENT: \(Int(coordinator.currentDailyInvestment)) HR").font(.vigil.system)
            Slider(value: $coordinator.currentDailyInvestment, in: 0...12, step: 1).tint(Color.accent.primary)
            Text("REQUIRED DAILY INVESTMENT: \(Int(coordinator.requiredDailyInvestment)) HR").font(.vigil.system)
            Slider(value: $coordinator.requiredDailyInvestment, in: 0...12, step: 1).tint(Color.accent.primary)
            Spacer()
            VIGILButton(title: "CONTINUE", isDisabled: coordinator.fieldOfFocus.isEmpty || coordinator.specificObjective.isEmpty, action: onContinue)
        }.padding()
    }
}

struct StrengthView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Text("PHASE 3: STRENGTH").font(.vigil.titleLarge).foregroundStyle(Color.accent.primary)
            Picker("CURRENT PHYSICAL STATE", selection: $coordinator.physicalState) { ForEach(["Skinny", "Average", "Athletic", "Overweight", "Obese"], id: \.self) { Text($0.uppercased()).tag($0) } }.pickerStyle(.segmented)
            Text("CURRENT MASS: \(Int(coordinator.currentMass)) KG").font(.vigil.system)
            Slider(value: $coordinator.currentMass, in: 30...200, step: 1).tint(Color.accent.primary)
            Text("TARGET MASS: \(Int(coordinator.targetMass)) KG").font(.vigil.system)
            Slider(value: $coordinator.targetMass, in: 30...200, step: 1).tint(Color.accent.primary)
            Text("TARGET TRAINING FREQUENCY: \(Int(coordinator.targetTrainingFrequency)) DAYS/WEEK").font(.vigil.system)
            Slider(value: $coordinator.targetTrainingFrequency, in: 0...7, step: 1).tint(Color.accent.primary)
            VIGILButton(title: "CONTINUE", action: onContinue)
        }.padding()
    }
}

struct VitalityView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Text("PHASE 4: VITALITY").font(.vigil.titleLarge).foregroundStyle(Color.accent.primary)
            DatePicker("CURRENT BEDTIME", selection: $coordinator.currentBedTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel)
            DatePicker("CURRENT WAKE TIME", selection: $coordinator.currentWakeTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel)
            DatePicker("TARGET BEDTIME", selection: $coordinator.targetBedTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel)
            DatePicker("TARGET WAKE TIME", selection: $coordinator.targetWakeTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel)
            VIGILButton(title: "CONTINUE", action: onContinue)
        }.padding()
    }
}

struct DailyGoalsConfirmationView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Text("DAILY GOAL CONFIRMATION").font(.vigil.titleLarge).foregroundStyle(Color.accent.primary)
            ScrollView {
                ForEach($coordinator.suggestedGoals) { $goal in
                    Button {
                        goal.active.toggle()
                    } label: {
                        HStack {
                            Text(goal.name).font(.vigil.body).foregroundStyle(Color.text.primary)
                            Spacer()
                            Image(systemName: goal.active ? "checkmark.square.fill" : "square")
                        }
                        .padding()
                        .background(Color.bg.secondary)
                        .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            VIGILButton(title: "CONTINUE", isDisabled: coordinator.suggestedGoals.filter(\.active).isEmpty, action: onContinue)
        }
        .padding()
    }
}
