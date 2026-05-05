//
//  StatBarsView.swift
//  VIGIL
//

import SwiftUI

struct StatBarsView: View {
    let player: Player

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            StatBarRowView(
                title: "INTELLECT",
                systemImage: "brain.head.profile",
                block: player.intellect,
                isDiscipline: false
            )
            StatBarRowView(
                title: "STRENGTH",
                systemImage: "figure.strengthtraining.traditional",
                block: player.strength,
                isDiscipline: false
            )
            StatBarRowView(
                title: "SPIRIT",
                systemImage: "flame.fill",
                block: player.spirit,
                isDiscipline: false
            )
            StatBarRowView(
                title: "DISCIPLINE",
                systemImage: "scope",
                block: player.discipline,
                isDiscipline: true
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatBarRowView: View {
    let title: String
    let systemImage: String
    let block: StatBlock
    let isDiscipline: Bool

    @State private var progressPhase: CGFloat = 0

    private var iconSize: CGFloat { isDiscipline ? 19 : 17 }
    private var barHeight: CGFloat { isDiscipline ? 11.5 : 8 }
    private var rowVerticalPadding: CGFloat { isDiscipline ? 2 : 0 }

    private var fillFraction: CGFloat {
        let div = max(block.xpToNextLevel, 1)
        return CGFloat(Double(block.currentXP) / Double(div)).clamped01
    }

    private var tint: Color {
        block.debuffActive ? Color.status.danger : Color.accent.primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue + 2) {
            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(tint.opacity(block.debuffActive ? 1 : 0.9))
                    .frame(width: iconSize + 8, alignment: .center)

                Text(title)
                    .font(Font.vigil.caption)
                    .foregroundStyle(Color.text.secondary)
                    .tracking(1.6)
                    .fixedSize()

                Spacer(minLength: 0)

                HStack(spacing: Spacing.xs.rawValue) {
                    Text("LV \(block.level)")
                        .font(Font.vigil.caption)
                        .foregroundStyle(Color.text.primary)
                        .fixedSize()

                    if block.debuffActive {
                        Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.status.danger)
                            .accessibilityLabel("Debuff active")
                    }
                }
            }

            GeometryReader { proxy in
                let trackWidth = max(8, proxy.size.width)
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.bg.secondary)
                        .frame(height: barHeight)

                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: trackWidth * progressPhase, height: barHeight)
                }
            }
            .frame(height: barHeight + rowVerticalPadding)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), level \(block.level)")
        .padding(.vertical, rowVerticalPadding * 1.75)
        .onAppear {
            runFillAnimation(to: fillFraction)
        }
        .onChange(of: block.currentXP) { _, _ in
            runFillAnimation(to: fillFraction)
        }
        .onChange(of: block.xpToNextLevel) { _, _ in
            runFillAnimation(to: fillFraction)
        }
    }

    private func runFillAnimation(to target: CGFloat) {
        if vigilReduceMotionEnabled() {
            progressPhase = target
            return
        }
        progressPhase = 0
        withAnimation(VIGILAnimations.standardEaseInOut) {
            progressPhase = target
        }
    }
}

private extension CGFloat {
    var clamped01: CGFloat {
        Swift.min(Swift.max(self, 0), 1)
    }
}
