//
//  BlockScheduler.swift
//  VIGIL
//

import Foundation
import SwiftData

/// Bridges `DeviceActivityMonitor` (extension process) to `ScreenTimeManager` (app process).
@MainActor
final class BlockScheduler {
    static let shared = BlockScheduler()

    private var isObservingDarwin = false

    private init() {}

    /// Begin listening for App Group + Darwin notifications from the monitor extension.
    func startObservingMonitorBridge() {
        guard !isObservingDarwin else { return }
        isObservingDarwin = true

        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = ScreenTimeAppGroupBridge.darwinNotifyName
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let raw = observer else { return }
                let sched = Unmanaged<BlockScheduler>.fromOpaque(raw).takeUnretainedValue()
                Task { @MainActor in
                    sched.flushPendingBridgeEvents()
                }
            },
            name,
            nil,
            .deliverImmediately
        )
    }

    func flushPendingBridgeEvents() {
        guard let context = ScreenTimeManager.shared.modelContext ?? VIGILPersistence.makeContext() else { return }
        ScreenTimeManager.shared.processPendingMonitorEvents(modelContext: context)
    }

    /// Called when the monitor extension reported usage past grace (`DeviceActivityEvent` threshold).
    func detectViolation(blockId: UUID) {
        guard let context = ScreenTimeManager.shared.modelContext ?? VIGILPersistence.makeContext() else { return }
        Task {
            await ScreenTimeManager.shared.onSchedulerViolation(blockId: blockId, modelContext: context)
        }
    }

    /// Called when the scheduled block interval ends cleanly.
    func blockCompleted(blockId: UUID) {
        guard let context = ScreenTimeManager.shared.modelContext ?? VIGILPersistence.makeContext() else { return }
        ScreenTimeManager.shared.onSchedulerBlockCompleted(blockId: blockId, modelContext: context)
    }
}
