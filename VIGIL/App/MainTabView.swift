//
//  MainTabView.swift
//  VIGIL
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(AppRouter.self) private var appRouter

    var body: some View {
        @Bindable var appRouter = appRouter
        TabView(selection: $appRouter.activeTab) {
            DashboardView()
                .tag(AppRouter.Tab.dashboard)
                .tabItem {
                    tabBarIcon("house.fill", tab: .dashboard)
                }

            QuestBoardView()
                .tag(AppRouter.Tab.quests)
                .tabItem {
                    tabBarIcon("scroll.fill", tab: .quests)
                }

            ProfileView()
                .tag(AppRouter.Tab.profile)
                .tabItem {
                    tabBarIcon("eye.fill", tab: .profile)
                }
        }
        .toolbarBackground(Color.bg.primary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(Color.accent.primary)
        .onAppear {
            applyTabBarAppearance()
        }
    }

    @ViewBuilder
    private func tabBarIcon(_ systemName: String, tab: AppRouter.Tab) -> some View {
        let selected = appRouter.activeTab == tab
        Image(systemName: systemName)
            .font(.system(size: 22, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(selected ? Color.accent.primary : Color.text.muted)
            .shadow(color: selected ? Color.accent.primary.opacity(0.85) : .clear, radius: selected ? 12 : 0)
    }

    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.bg.primary)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
