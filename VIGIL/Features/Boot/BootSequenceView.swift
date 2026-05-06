//
//  BootSequenceView.swift
//  VIGIL
//

import SwiftUI

struct BootSequenceView: View {
    let context: AppRouter.BootContext
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    private var reduceMotion: Bool {
        accessibilityReduceMotion || vigilReduceMotionEnabled()
    }

    @State private var timelineStart = Date()

    private let letters = Array("VIGIL")
    private var duration: UInt64 {
        context == .standard ? 3_000_000_000 : 4_000_000_000
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(timelineStart)

            ZStack {
                Color.bg.primary
                    .ignoresSafeArea()

                bootContent(elapsed: elapsed).vigilGlitch(active: elapsed > 1.4 && elapsed < 2.4)
            }
        }
        .transition(.opacity)
        .preferredColorScheme(.dark)
        .task {
            try? await Task.sleep(nanoseconds: duration)
            onComplete()
        }
    }

    @ViewBuilder
    private func bootContent(elapsed: Double) -> some View {
        VStack(spacing: Spacing.xl.rawValue) {
            Image(systemName: "eye.fill")
                .font(.system(size: elapsed < 0.6 ? 48 : 62, weight: .medium))
                .foregroundStyle(Color.accent.primary.opacity(elapsed < 0.6 ? 0.35 : 1))
            Text("VIGIL")
                .font(.vigil.display)
                .tracking(Font.vigil.displayTracking)
                .foregroundStyle(Color.text.primary)
            if elapsed > 2.4 {
                ScanlineOverlay()
                    .frame(height: 40)
            }
            if context != .standard && elapsed > 2.7 {
                Text(contextLine)
                    .font(.vigil.system)
                    .foregroundStyle(Color.text.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contextLine: String {
        switch context {
        case .postOnboarding: "INITIALISATION COMPLETE. SUBJECT [PLAYER] BOUND."
        case .newDay: "DAY [N]. THE SYSTEM HAS BEEN WATCHING."
        case .postPunishment: "YOUR ABSENCE WAS NOTED."
        case .streakMilestone: "DAY [N] CONFIRMED. CONTINUE."
        case .rankChange: "RANK STATUS: MODIFIED."
        case .standard: ""
        }
    }
}
