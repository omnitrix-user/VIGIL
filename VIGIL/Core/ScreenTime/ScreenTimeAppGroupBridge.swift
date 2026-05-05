//
//  ScreenTimeAppGroupBridge.swift
//  VIGIL
//

import Foundation

/// Cross-process signals between `DeviceActivityMonitor` and the main app via the shared App Group.
/// Not domain model data — ephemeral bridge payloads only.
enum ScreenTimeAppGroupBridge {
    private static let suiteName = "group.com.ayush.vigil.VIGIL"
    private static let intervalStartKeyPrefix = "vigil.screenTime.intervalStart."
    private static let pendingEventFile = "vigil_monitor_pending_event.json"

    /// Posted on Darwin notify when extension writes a pending event (optional wake hint).
    static let darwinNotifyName = "com.vigil.screenTime.monitorEvent" as CFString

    struct PendingEvent: Codable, Equatable, Sendable {
        enum Kind: String, Codable {
            case violation
            case completed
        }

        var kind: Kind
        var blockId: UUID
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    static func setIntervalStartEpoch(forActivityRaw raw: String, epoch: TimeInterval) {
        defaults?.set(epoch, forKey: intervalStartKeyPrefix + raw)
    }

    static func intervalStartEpoch(forActivityRaw raw: String) -> TimeInterval? {
        defaults?.double(forKey: intervalStartKeyPrefix + raw)
    }

    static func clearIntervalStart(forActivityRaw raw: String) {
        defaults?.removeObject(forKey: intervalStartKeyPrefix + raw)
    }

    static func writePendingEvent(_ event: PendingEvent) throws {
        guard let base = containerURL() else {
            throw ScreenTimeBridgeError.appGroupUnavailable
        }
        let url = base.appendingPathComponent(pendingEventFile)
        let data = try JSONEncoder().encode(event)
        try data.write(to: url, options: [.atomic])

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            darwinNotifyName,
            nil,
            nil,
            true
        )
    }

    static func readAndConsumePendingEvent() -> PendingEvent? {
        guard let base = containerURL() else { return nil }
        let url = base.appendingPathComponent(pendingEventFile)
        guard let data = try? Data(contentsOf: url) else { return nil }
        try? FileManager.default.removeItem(at: url)
        return try? JSONDecoder().decode(PendingEvent.self, from: data)
    }
}

enum ScreenTimeBridgeError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "App Group container unavailable. Enable the App Group capability for Screen Time bridge events."
        }
    }
}
