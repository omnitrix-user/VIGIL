//
//  VIGILApp.swift
//  VIGIL
//
//  Created by Qualtech on 06/05/26.
//

import SwiftUI
import SwiftData
import UIKit
import BackgroundTasks

@main
struct VIGILApp: App {
    @State private var appRouter = AppRouter()
    @Environment(\.scenePhase) private var scenePhase

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Player.self,
            Goal.self,
            GoalCompletion.self,
            Quest.self,
            DayLog.self,
            AIVerdict.self,
            PhoneBlockRecord.self,
            TourState.self,
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

    init() {
        MorningTriggerScheduler.shared.register()
        IdleCheckScheduler.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchGate(appRouter: $appRouter)
                .modelContainer(sharedModelContainer)
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { @MainActor in
                        let context = ModelContext(sharedModelContainer)
                        await QuestTriggerService.shared.evaluateTriggers(modelContext: context)
                    }
                }
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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.createdAt) private var players: [Player]
    @State private var showOnboarding = false

    var body: some View {
        MainTabView()
            .environment(appRouter)
            .task {
                MorningTriggerScheduler.shared.modelContext = modelContext
                IdleCheckScheduler.shared.modelContext = modelContext
                showOnboarding = players.isEmpty
                if !showOnboarding {
                    appRouter.refreshBootTriggerState()
                    Task { await QuestTriggerService.shared.evaluateTriggers(modelContext: modelContext) }
                    if let player = players.first {
                        MorningTriggerScheduler.shared.schedule(for: player)
                    }
                    IdleCheckScheduler.shared.schedule()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if players.isEmpty {
                    showOnboarding = true
                } else {
                    appRouter.refreshBootTriggerState()
                    Task { await QuestTriggerService.shared.evaluateTriggers(modelContext: modelContext) }
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
