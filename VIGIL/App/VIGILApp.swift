//
//  VIGILApp.swift
//  VIGIL
//
//  Created by Qualtech on 06/05/26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct VIGILApp: App {
    @State private var appRouter = AppRouter()

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Player.self,
            Goal.self,
            GoalCompletion.self,
            Quest.self,
            DayLog.self,
            AIVerdict.self,
            PhoneBlockRecord.self,
        ])
        // CloudKit: when enabling sync, configure ModelConfiguration with CloudKit
        // (e.g. `cloudKitDatabase: .private("iCloud.<your-container>)")`) and migrate.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppLaunchGate(appRouter: $appRouter)
                .modelContainer(sharedModelContainer)
        }
    }
}

private struct AppLaunchGate: View {
    @Binding var appRouter: AppRouter
    @Query(sort: \Player.createdAt) private var players: [Player]
    @State private var showOnboarding = false

    var body: some View {
        MainTabView()
            .environment(appRouter)
            .task {
                showOnboarding = players.isEmpty
                if !showOnboarding {
                    appRouter.refreshBootTriggerState()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if players.isEmpty {
                    showOnboarding = true
                } else {
                    appRouter.refreshBootTriggerState()
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingHostView {
                    showOnboarding = false
                    appRouter.refreshBootTriggerState()
                }
                .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: bootCoverBinding) {
                BootSequenceView {
                    appRouter.completeBootSequence()
                }
                .interactiveDismissDisabled()
            }
    }

    private var bootCoverBinding: Binding<Bool> {
        Binding(
            get: { !showOnboarding && appRouter.shouldShowBoot },
            set: { appRouter.shouldShowBoot = $0 }
        )
    }
}
