//
//  DashboardView.swift
//  VIGIL
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \Player.createdAt) private var players: [Player]

    private var player: Player? {
        players.first
    }

    var body: some View {
        ZStack {
            Color.bg.primary
                .ignoresSafeArea()

            if let player {
                dashboardContent(player: player)
            } else {
                Text("The system is waiting for you.")
                    .font(Font.vigil.body)
                    .foregroundStyle(Color.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.lg.rawValue)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func dashboardContent(player: Player) -> some View {
        GeometryReader { proxy in
            let topHeight = proxy.size.height * 0.5

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                    RankCardView(player: player)
                    StatBarsView(player: player)
                }
                .padding(.horizontal, Spacing.md.rawValue)
                .padding(.top, Spacing.sm.rawValue)
                .frame(height: topHeight, alignment: .top)
                .clipped()

                Rectangle()
                    .fill(Color.bg.tertiary.opacity(0.55))
                    .frame(height: 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl.rawValue) {
                        TodayGoalsView(player: player)

                        streakFooter(player: player)
                            .padding(.horizontal, Spacing.md.rawValue)
                            .padding(.bottom, Spacing.xxl.rawValue)
                    }
                    .padding(.top, Spacing.md.rawValue)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private func streakFooter(player: Player) -> some View {
        Text("Day \(player.showedUpStreak) — The system is watching.")
            .font(Font.vigil.caption)
            .foregroundStyle(Color.text.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }
}
