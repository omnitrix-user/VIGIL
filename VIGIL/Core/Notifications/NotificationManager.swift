//
//  NotificationManager.swift
//  VIGIL
//

import SwiftData
import UIKit
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Block violation (full consequence). Fires immediately; heavy haptic on post.
    func postBlockViolationNotification(player: Player? = nil) async {
        guard await shouldDeliverViolations(player: player) else { return }

        let content = UNMutableNotificationContent()
        content.title = NotificationContent.BlockViolation.title
        content.body = NotificationContent.BlockViolation.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "vigil.screenTime.violation.\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.05, repeats: false)
        )

        UIImpactFeedbackGenerator(style: .heavy).prepare()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        try? await center.add(request)
    }

    /// In-block warning before XP deduction; same title family, lighter consequence copy.
    func postBlockViolationWarningNotification(player: Player? = nil) async {
        guard await shouldDeliverViolations(player: player) else { return }

        let content = UNMutableNotificationContent()
        content.title = NotificationContent.BlockViolationWarning.title
        content.body = NotificationContent.BlockViolationWarning.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "vigil.screenTime.warning.\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.05, repeats: false)
        )

        UIImpactFeedbackGenerator(style: .heavy).prepare()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        try? await center.add(request)
    }

    /// Prefer reading `Player.notificationsViolations` when `modelContext` is available.
    func shouldDeliverViolations(player: Player?) async -> Bool {
        if let player, !player.notificationsViolations {
            return false
        }
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func postMorningQuestNotification(day: Int, questTitle: String, player: Player?) async {
        guard await shouldDeliverViolations(player: player) else { return }
        let body = NotificationContent.Morning.variants.randomElement()?
            .replacingOccurrences(of: "[N]", with: "\(day)") ?? "Player. New cycle."
        await post(title: "VIGIL", body: "\(body) [\(questTitle)]")
    }

    func postIdle18hNotification(player: Player?) async {
        guard await shouldDeliverViolations(player: player) else { return }
        await post(title: "VIGIL", body: NotificationContent.Idle18h.variants.randomElement() ?? "Absence logged.")
    }

    func postIdle48hNotification(player: Player?) async {
        guard await shouldDeliverViolations(player: player) else { return }
        await post(title: "VIGIL", body: NotificationContent.Idle48h.variants.randomElement() ?? "Two days lost.")
    }

    func postIdle7dNotification(player: Player?) async {
        guard await shouldDeliverViolations(player: player) else { return }
        await post(title: "VIGIL", body: NotificationContent.Idle7d.variants.randomElement() ?? "Re-entry required.")
    }

    private func post(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "vigil.system.\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.05, repeats: false)
        )
        try? await center.add(request)
    }
}
