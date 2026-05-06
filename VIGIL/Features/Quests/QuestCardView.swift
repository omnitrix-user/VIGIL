//
//  QuestCardView.swift
//  VIGIL
//

import SwiftUI

struct QuestCardView: View {
    let quest: Quest

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            HStack {
                Text(quest.questType.rawValue.uppercased())
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.text.primary)
                    .padding(.horizontal, Spacing.sm.rawValue)
                    .padding(.vertical, Spacing.xs.rawValue)
                    .background(typeColor.opacity(0.24))
                    .clipShape(Capsule())
                Spacer()
            }

            Text(quest.title.uppercased())
                .font(Font.vigil.headline)
                .foregroundStyle(Color.text.primary)
                .multilineTextAlignment(.leading)

            Text(deadlineText)
                .font(Font.vigil.caption)
                .foregroundStyle(Color.text.secondary)

            Text(xpText)
                .font(Font.vigil.caption)
                .foregroundStyle(Color.accent.secondary)
        }
        .padding(Spacing.md.rawValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bg.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var xpText: String {
        "XP \(quest.xpReward) / -\(quest.xpPenalty)"
    }

    private var deadlineText: String {
        guard let deadline = quest.deadline else { return "NO DEADLINE" }
        let remaining = Int(deadline.timeIntervalSinceNow)
        if remaining <= 0 { return "DEADLINE PASSED" }
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        return "\(hours)H \(minutes)M REMAINING"
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
