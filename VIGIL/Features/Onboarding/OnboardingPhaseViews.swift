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
        ScrollView {
            VStack(spacing: Spacing.md.rawValue) {
                Text("PHASE 2: INTELLIGENCE").font(.vigil.titleLarge).foregroundStyle(Color.accent.primary)
                TextField("FIELD OF FOCUS", text: $coordinator.fieldOfFocus).padding().background(Color.bg.secondary).overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                TextField("SPECIFIC OBJECTIVE", text: $coordinator.specificObjective).padding().background(Color.bg.secondary).overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                Picker("TARGET COMPLETION", selection: $coordinator.targetCompletion) { ForEach(["1mo", "3mo", "6mo", "1yr", "2yr+"], id: \.self) { Text($0.uppercased()).tag($0) } }.pickerStyle(.segmented)
                Text("CURRENT DAILY INVESTMENT: \(Int(coordinator.currentDailyInvestment)) HR").font(.vigil.system)
                Slider(value: $coordinator.currentDailyInvestment, in: 0...12, step: 1).tint(Color.accent.primary)
                Text("REQUIRED DAILY INVESTMENT: \(Int(coordinator.requiredDailyInvestment)) HR").font(.vigil.system)
                Slider(value: $coordinator.requiredDailyInvestment, in: 0...12, step: 1).tint(Color.accent.primary)
            }.padding()
        }
        .safeAreaInset(edge: .bottom) {
            VIGILButton(title: "CONTINUE", isDisabled: coordinator.fieldOfFocus.isEmpty || coordinator.specificObjective.isEmpty, action: onContinue)
                .padding()
                .background(Color.bg.primary)
        }
    }
}

struct StrengthView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md.rawValue) {
                Text("PHASE 3: STRENGTH").font(.vigil.titleLarge).foregroundStyle(Color.accent.primary)
                Picker("CURRENT PHYSICAL STATE", selection: $coordinator.physicalState) { ForEach(["Skinny", "Average", "Athletic", "Overweight", "Obese"], id: \.self) { Text($0.uppercased()).tag($0) } }.pickerStyle(.segmented)
                Text("CURRENT MASS: \(Int(coordinator.currentMass)) KG").font(.vigil.system)
                Slider(value: $coordinator.currentMass, in: 30...200, step: 1).tint(Color.accent.primary)
                Text("TARGET MASS: \(Int(coordinator.targetMass)) KG").font(.vigil.system)
                Slider(value: $coordinator.targetMass, in: 30...200, step: 1).tint(Color.accent.primary)
                Text("TARGET TRAINING FREQUENCY: \(Int(coordinator.targetTrainingFrequency)) DAYS/WEEK").font(.vigil.system)
                Slider(value: $coordinator.targetTrainingFrequency, in: 0...7, step: 1).tint(Color.accent.primary)
            }.padding()
        }
        .safeAreaInset(edge: .bottom) {
            VIGILButton(title: "CONTINUE", action: onContinue)
                .padding()
                .background(Color.bg.primary)
        }
    }
}

struct VitalityView: View {
    @Bindable var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    @State private var editingField: TimeField?

    private enum TimeField: String, Identifiable {
        case currentBedtime
        case currentWake
        case targetBedtime
        case targetWake

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Text("PHASE 4: VITALITY").font(.vigil.titleLarge).foregroundStyle(Color.accent.primary)
            timeRow(label: "CURRENT BEDTIME", value: coordinator.currentBedTime) { editingField = .currentBedtime }
            timeRow(label: "CURRENT WAKE TIME", value: coordinator.currentWakeTime) { editingField = .currentWake }
            timeRow(label: "TARGET BEDTIME", value: coordinator.targetBedTime) { editingField = .targetBedtime }
            timeRow(label: "TARGET WAKE TIME", value: coordinator.targetWakeTime) { editingField = .targetWake }
            Spacer(minLength: 0)
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            VIGILButton(title: "CONTINUE", isDisabled: !allTimesSet, action: onContinue)
                .padding()
                .background(Color.bg.primary)
        }
        .sheet(item: $editingField) { field in
            TimePickerSheet(
                title: sheetTitle(for: field),
                selection: binding(for: field)
            )
            .presentationDetents([.medium])
        }
    }

    private var allTimesSet: Bool {
        true
    }

    private func timeRow(label: String, value: Date, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(.vigil.system).foregroundStyle(Color.text.secondary)
                Spacer()
                Text(Self.timeFormatter.string(from: value))
                    .font(.vigil.body)
                    .foregroundStyle(Color.text.primary)
            }
            .padding()
            .background(Color.bg.secondary)
            .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func sheetTitle(for field: TimeField) -> String {
        switch field {
        case .currentBedtime: "SET CURRENT BEDTIME"
        case .currentWake: "SET CURRENT WAKE TIME"
        case .targetBedtime: "SET TARGET BEDTIME"
        case .targetWake: "SET TARGET WAKE TIME"
        }
    }

    private func binding(for field: TimeField) -> Binding<Date> {
        switch field {
        case .currentBedtime: $coordinator.currentBedTime
        case .currentWake: $coordinator.currentWakeTime
        case .targetBedtime: $coordinator.targetBedTime
        case .targetWake: $coordinator.targetWakeTime
        }
    }

    private static let h12Locale = Locale(identifier: "en_US@hc=h12")

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = h12Locale
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

private struct TimePickerSheet: View {
    let title: String
    @Binding var selection: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.md.rawValue) {
            Text(title)
                .font(.vigil.headline)
                .foregroundStyle(Color.accent.primary)
            DatePicker(
                "",
                selection: $selection,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "en_US@hc=h12"))
            VIGILButton(title: "CONFIRM") { dismiss() }
        }
        .padding()
        .background(Color.bg.primary.ignoresSafeArea())
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
