//
//  VigilDeviceActivityMonitor.swift
//  VIGILMonitorExtension
//
//  Add this folder as a **Device Activity Monitor Extension** target in Xcode (see README below).
//  `DeviceActivityMonitor` is **not** available in the main app target.
//

import DeviceActivity
import Foundation

private enum MonitorBridge {
    /// **Must match** `ScreenTimeAppGroupBridge` in the main app.
    static let suite = "group.com.ayush.vigil.VIGIL"
    static let pendingFile = "vigil_monitor_pending_event.json"
    static let intervalStartPrefix = "vigil.screenTime.intervalStart."

    static let graceSeconds: TimeInterval = 15

    enum PendingKind: String, Codable {
        case violation
        case completed
    }

    struct Pending: Codable {
        var kind: PendingKind
        var blockId: UUID
    }

    static func parseBlockId(from activityRaw: String) -> UUID? {
        let prefix = "vigil.block."
        guard activityRaw.hasPrefix(prefix) else { return nil }
        let rest = String(activityRaw.dropFirst(prefix.count))
        return UUID(uuidString: rest)
    }

    static func setIntervalStart(activityRaw: String) {
        let defaults = UserDefaults(suiteName: suite)
        defaults?.set(Date().timeIntervalSince1970, forKey: intervalStartPrefix + activityRaw)
    }

    static func clearIntervalStart(activityRaw: String) {
        let defaults = UserDefaults(suiteName: suite)
        defaults?.removeObject(forKey: intervalStartPrefix + activityRaw)
    }

    static func intervalStartEpoch(activityRaw: String) -> TimeInterval? {
        let defaults = UserDefaults(suiteName: suite)
        let value = defaults?.double(forKey: intervalStartPrefix + activityRaw) ?? 0
        return value > 0 ? value : nil
    }

    static func writePending(_ pending: Pending) throws {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite) else { return }
        let url = dir.appendingPathComponent(pendingFile)
        let data = try JSONEncoder().encode(pending)
        try data.write(to: url, options: [.atomic])
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            "com.vigil.screenTime.monitorEvent" as CFString,
            nil,
            nil,
            true
        )
    }
}

/// **Real device testing required** — thresholds fire only when matching `DeviceActivityEvent` maps are registered
/// from the main app (`FamilyActivityPicker` tokens). Simulator does not exercise production enforcement.
@objc(VigilDeviceActivityMonitor)
final class VigilDeviceActivityMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        MonitorBridge.setIntervalStart(activityRaw: activity.rawValue)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        defer { MonitorBridge.clearIntervalStart(activityRaw: activity.rawValue) }
        guard let blockId = MonitorBridge.parseBlockId(from: activity.rawValue) else { return }
        let pending = MonitorBridge.Pending(kind: .completed, blockId: blockId)
        try? MonitorBridge.writePending(pending)
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        guard let blockId = MonitorBridge.parseBlockId(from: activity.rawValue) else { return }

        if let start = MonitorBridge.intervalStartEpoch(activityRaw: activity.rawValue) {
            let elapsed = Date().timeIntervalSince1970 - start
            if elapsed < MonitorBridge.graceSeconds { return }
        }

        let pending = MonitorBridge.Pending(kind: .violation, blockId: blockId)
        try? MonitorBridge.writePending(pending)
    }
}
