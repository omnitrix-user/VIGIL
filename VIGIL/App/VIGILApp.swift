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
            MainTabView()
                .environment(appRouter)
                .modelContainer(sharedModelContainer)
                .task {
                    appRouter.refreshBootTriggerState()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    appRouter.refreshBootTriggerState()
                }
                .fullScreenCover(isPresented: bootCoverBinding) {
                    BootSequenceView {
                        appRouter.completeBootSequence()
                    }
                    .interactiveDismissDisabled()
                }
        }
    }

    private var bootCoverBinding: Binding<Bool> {
        Binding(
            get: { appRouter.shouldShowBoot },
            set: { appRouter.shouldShowBoot = $0 }
        )
    }
}
