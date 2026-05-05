//
//  TodayGoalsView.swift
//  VIGIL
//

import SwiftUI

struct TodayGoalsView: View {
    let player: Player

    @State private var expandedGoalIDs: Set<UUID> = []

    private var todaysGoals: [Goal] {
        player.goals
            .filter { GoalDashboardFormatting.isActiveGoalToday(for: $0) }
            .sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            if todaysGoals.isEmpty {
                emptyState
            } else {
                goalsList
            }

            Button(action: {}) {
                Text("ADD SESSION")
                    .font(Font.vigil.headline)
                    .tracking(2.8)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md.rawValue)
                    .background(Color.accent.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add unregistered session")
        }
        .padding(.horizontal, Spacing.md.rawValue)
        .padding(.bottom, Spacing.xl.rawValue)
    }

    private var emptyState: some View {
        Text("No goals defined. The system is waiting.")
            .font(Font.vigil.body)
            .foregroundStyle(Color.text.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl.rawValue)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var goalsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            ForEach(todaysGoals, id: \.id) { goal in
                GoalRowView(
                    goal: goal,
                    loggedToday: GoalDashboardFormatting.loggedValueToday(for: goal),
                    isExpanded: expandedGoalIDs.contains(goal.id),
                    onToggleExpanded: {
                        toggle(goal.id)
                    }
                )
            }
        }
    }

    private func toggle(_ id: UUID) {
        if vigilReduceMotionEnabled() {
            if expandedGoalIDs.contains(id) {
                expandedGoalIDs.remove(id)
            } else {
                expandedGoalIDs.insert(id)
            }
        } else {
            withAnimation(VIGILAnimations.standardEaseInOut) {
                if expandedGoalIDs.contains(id) {
                    expandedGoalIDs.remove(id)
                } else {
                    expandedGoalIDs.insert(id)
                }
            }
        }
    }
}
