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
            // Schema migration fallback: stat rename + onboarding redesign can invalidate local store.
            // We intentionally wipe the local SwiftData store once and rebuild a clean container.
            wipeSwiftDataStoreFiles()
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppLaunchGate(appRouter: $appRouter)
                .modelContainer(sharedModelContainer)
        }
    }
}

private func wipeSwiftDataStoreFiles() {
    let fm = FileManager.default
    guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
    guard let contents = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) else { return }
    for url in contents where url.lastPathComponent.contains(".store") {
        try? fm.removeItem(at: url)
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
                    appRouter.bootContext = .postOnboarding
                    appRouter.shouldShowBoot = true
                    appRouter.refreshBootTriggerState()
                }
                .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: bootCoverBinding) {
                BootSequenceView(context: appRouter.bootContext) {
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
