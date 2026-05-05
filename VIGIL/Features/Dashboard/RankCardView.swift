//
//  RankCardView.swift
//  VIGIL
//

import SwiftUI

struct RankCardView: View {
    let player: Player

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                gradeBadge
                identityBlock
                if player.hasGoldenCrown || player.hasUnawokenTag {
                    statusRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if player.hasGoldenCrown {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.accent.gold)
                    .shadow(color: Color.accent.gold.opacity(0.45), radius: 8)
                    .padding(.top, Spacing.xs.rawValue)
                    .accessibilityLabel("Golden crown unlocked")
            }
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.sm.rawValue, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.sm.rawValue, style: .continuous)
                .strokeBorder(Color.accent.primary.opacity(0.28), lineWidth: 1)
        )
    }

    private var gradeBadge: some View {
        Text(player.currentRank.rawValue)
            .font(Font.vigil.display)
            .foregroundStyle(rankColor(for: player.currentRank))
            .minimumScaleFactor(0.85)
            .lineLimit(1)
            .frame(minWidth: 76, alignment: .center)
            .padding(.horizontal, Spacing.lg.rawValue)
            .padding(.vertical, Spacing.sm.rawValue + 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(rankColor(for: player.currentRank).opacity(0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(rankColor(for: player.currentRank).opacity(0.65), lineWidth: 1)
            )
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rank \(player.currentRank.rawValue)")
    }

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            Text(player.username.isEmpty ? "PLAYER" : player.username)
                .font(Font.vigil.headline)
                .foregroundStyle(Color.text.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let title = player.activeTitle, !title.isEmpty {
                Text(title.uppercased())
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.text.muted)
                    .tracking(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            if player.hasUnawokenTag {
                Text("UNAWAKENED")
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.status.danger)
                    .padding(.horizontal, Spacing.sm.rawValue)
                    .padding(.vertical, Spacing.xs.rawValue + 2)
                    .background(
                        Capsule()
                            .strokeBorder(Color.status.danger.opacity(0.55), lineWidth: 1)
                    )
                    .fixedSize()
            }
            Spacer(minLength: 0)
        }
    }

    private func rankColor(for rank: Rank) -> Color {
        switch rank {
        case Rank.E:
            Color.rank.E
        case Rank.D:
            Color.rank.D
        case Rank.C:
            Color.rank.C
        case Rank.B:
            Color.rank.B
        case Rank.A:
            Color.rank.A
        case Rank.S:
            Color.rank.S
        case Rank.SS:
            Color.rank.SS
        case Rank.SSS:
            Color.rank.SSS
        }
    }
}
