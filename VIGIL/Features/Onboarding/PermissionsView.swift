//
//  PermissionsView.swift
//  VIGIL
//

import SwiftUI

struct PermissionsView: View {
    let onFinish: () -> Void

    @State private var grantedNotifications = false
    @State private var grantedHealthKit = false
    @State private var grantedScreenTime = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            permissionBlock(
                title: "Notifications",
                message: "The system requires notifications to deliver verdicts in real time. Without it, judgement is delayed.",
                granted: grantedNotifications,
                action: requestNotifications
            )
            permissionBlock(
                title: "HealthKit",
                message: "The system requires health data to observe your output. Without it, analysis remains incomplete.",
                granted: grantedHealthKit,
                action: requestHealthKit
            )
            permissionBlock(
                title: "FamilyControls",
                message: "The system requires Screen Time authority to enforce no-phone blocks. Without it, discipline cannot be verified.",
                granted: grantedScreenTime,
                action: requestScreenTime
            )

            Spacer()

            Button(action: onFinish) {
                Text("ENTER THE SYSTEM")
                    .font(Font.vigil.headline)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md.rawValue)
                    .background(Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
    }

    private func permissionBlock(title: String, message: String, granted: Bool, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text(title.uppercased())
                .font(Font.vigil.headline)
                .foregroundStyle(Color.accent.primary)
            Text(message)
                .font(Font.vigil.system)
                .foregroundStyle(Color.text.secondary)
            HStack {
                Button(action: action) {
                    Text("GRANT ACCESS")
                        .font(Font.vigil.body)
                        .foregroundStyle(Color.bg.primary)
                        .padding(.horizontal, Spacing.md.rawValue)
                        .padding(.vertical, Spacing.sm.rawValue)
                        .background(Color.accent.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Text("SKIP")
                        .font(Font.vigil.body)
                        .foregroundStyle(Color.text.secondary)
                        .padding(.horizontal, Spacing.md.rawValue)
                        .padding(.vertical, Spacing.sm.rawValue)
                        .background(Color.bg.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
                if granted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.status.success)
                }
            }
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func requestNotifications() {
        Task {
            grantedNotifications = await NotificationManager.shared.requestAuthorizationIfNeeded()
        }
    }

    private func requestHealthKit() {
        Task {
            do {
                try await HealthKitManager.shared.requestAuthorization()
                grantedHealthKit = true
            } catch {
                grantedHealthKit = false
            }
        }
    }

    private func requestScreenTime() {
        Task {
            do {
                try await ScreenTimeManager.shared.requestAuthorization()
                grantedScreenTime = true
            } catch {
                grantedScreenTime = false
            }
        }
    }
}
