//
//  DashboardView.swift
//  VIGIL
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.createdAt) private var players: [Player]
    @State private var showTour = false

    private var player: Player? {
        players.first
    }

    var body: some View {
        ZStack {
            Color.bg.primary
                .ignoresSafeArea()

            if let player {
                dashboardContent(player: player)
                    .task(id: player.id) {
                        await runHealthSynchronization(for: player)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .vigilHealthKitDataChanged)) { _ in
                        guard let current = players.first else { return }
                        Task {
                            await runHealthSynchronization(for: current)
                        }
                    }
            } else {
                Text("The system is waiting for you.")
                    .font(Font.vigil.body)
                    .foregroundStyle(Color.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.lg.rawValue)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button { showTour = true } label: {
                    Text("[?]")
                        .font(.vigil.system)
                        .foregroundStyle(Color.accent.primary)
                        .padding(Spacing.sm.rawValue)
                        .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.md.rawValue)
            }
        }
        .tour(
            id: .dashboard,
            content: TourContentRegistry.content(for: .dashboard),
            forceShow: $showTour,
            autoShow: true
        )
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
                        VIGILButton(title: "MANAGE DAILY GOALS", action: {})
                            .padding(.horizontal, Spacing.md.rawValue)
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

    @MainActor
    private func runHealthSynchronization(for player: Player) async {
        try? await HealthKitManager.shared.requestAuthorization()
        await HealthKitStatSync.syncTodayHealthIntoPlayer(
            player: player,
            modelContext: modelContext
        )
        await HealthKitManager.shared.startBackgroundObserversIfNeeded()
    }
}
