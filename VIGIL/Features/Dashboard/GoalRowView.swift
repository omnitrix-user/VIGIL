//
//  GoalRowView.swift
//  VIGIL
//

import SwiftUI

struct GoalRowView: View {
    let goal: Goal
    let loggedToday: Double
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    let onStartSession: () -> Void

    private var xpAvailableLabel: String {
        GoalDashboardFormatting.xpPotentialLabel(for: goal, loggedToday: loggedToday)
    }

    private var progressLabel: String {
        GoalDashboardFormatting.progressLabel(for: goal, loggedToday: loggedToday)
    }

    private var tint: Color {
        Color.goalAccent(hex: goal.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Button(action: onToggleExpanded) {
                headerRow
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens session controls.")

            if isExpanded {
                expansionBlock
                    .transition(.opacity)
            }
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.secondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.sm.rawValue, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.sm.rawValue, style: .continuous)
                .strokeBorder(tint.opacity(isExpanded ? 0.56 : 0.22), lineWidth: 1)
        )
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: Spacing.md.rawValue) {
            Image(systemName: goal.icon.isEmpty ? "target" : goal.icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                Text(goal.name.uppercased())
                    .font(Font.vigil.headline)
                    .foregroundStyle(Color.text.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(progressLabel)
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.text.secondary)
                    .fixedSize()

                Text(xpAvailableLabel)
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.accent.secondary)
                    .fixedSize()
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.text.muted)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .padding(.leading, Spacing.sm.rawValue)
        }
        .padding(.bottom, Spacing.xs.rawValue)
    }

    @ViewBuilder
    private var expansionBlock: some View {
        switch goal.goalType {
        case GoalType.duration:
            Button(action: onStartSession) {
                Text("START SESSION")
                    .font(Font.vigil.headline)
                    .tracking(3)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm.rawValue)
                    .background(Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .opacity(goal.isActive ? 1 : 0.45)
            .disabled(!goal.isActive)
            .accessibilityLabel("Start session for \(goal.name)")
        default:
            Text("USE PROFILE FOR MANUAL LOGGING.")
                .font(Font.vigil.caption)
                .foregroundStyle(Color.text.muted)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum GoalDashboardFormatting {
    static func isActiveGoalToday(for goal: Goal, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        guard goal.isActive else { return false }
        return calendar.startOfDay(for: goal.startDate) <= calendar.startOfDay(for: now)
    }

    static func loggedValueToday(for goal: Goal, calendar: Calendar = .current, now: Date = Date()) -> Double {
        goal.completions.reduce(0) { partial, completion in
            calendar.isDateInToday(completion.loggedAt) ? partial + completion.value : partial
        }
    }

    static func progressLabel(for goal: Goal, loggedToday: Double) -> String {
        switch goal.goalType {
        case GoalType.duration:
            let current = Int(loggedToday.rounded(.towardZero))
            let target = Int(goal.targetValue.rounded(.towardZero))
            return "\(current) / \(target) \(goal.unit)"
        case GoalType.count:
            let current = Int(loggedToday.rounded(.towardZero))
            let target = Int(goal.targetValue.rounded(.towardZero))
            return "\(current) / \(target) \(goal.unit)"
        case GoalType.boolean:
            let threshold = Swift.max(goal.targetValue, 1)
            return loggedToday >= threshold ? "COMPLETE" : "NOT COMPLETE"
        }
    }

    static func xpPotentialLabel(for goal: Goal, loggedToday: Double) -> String {
        switch goal.goalType {
        case GoalType.boolean:
            let threshold = Swift.max(goal.targetValue, 1)
            return loggedToday >= threshold ? "CLAIMED TODAY" : "+\(goal.xpPerUnit) XP IF COMPLETED"
        case GoalType.duration, GoalType.count:
            let delta = Swift.max(goal.targetValue - loggedToday, 0)
            let approximate = Swift.max(delta * Double(goal.xpPerUnit), 0)
            return "UP TO \(Int(approximate.rounded())) XP TODAY"
        }
    }
}

private extension Color {
    static func goalAccent(hex: String) -> Color {
        vigilParseHexFlexible(hex, fallback: Color.accent.secondary)
    }

    static func vigilParseHexFlexible(_ raw: String, fallback: Color) -> Color {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 {
            s = s.map { String($0) + String($0) }.joined()
        }
        guard s.count == 6, let value = UInt32(s, radix: 16), value != 0 else { return fallback }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
