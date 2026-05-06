import SwiftUI
import UIKit

struct TourOverlayView: View {
    let content: TourContent
    let onSkip: () -> Void
    let onAcknowledge: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                Text("[SYSTEM BRIEFING]")
                    .font(.vigil.caption)
                    .foregroundStyle(Color.text.muted)
                Text(content.title)
                    .font(.vigil.display)
                    .tracking(Font.vigil.displayTracking)
                    .foregroundStyle(Color.accent.primary)
                Text(content.body.uppercased())
                    .font(.vigil.body)
                    .foregroundStyle(Color.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .background(Color.bg.secondary)
                    .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                    .overlay(ScanlineOverlay())
                HStack(spacing: Spacing.sm.rawValue) {
                    Button(action: onSkip) {
                        Text("[SKIP]")
                            .font(.vigil.headline)
                            .foregroundStyle(Color.text.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md.rawValue)
                            .overlay(Rectangle().stroke(Color.text.muted, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    VIGILButton(title: "ACKNOWLEDGED", action: onAcknowledge)
                }
            }
            .padding(Spacing.md.rawValue)
            .background(Color.bg.primary)
            .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
            .vigilGlitch(active: true)
            .padding(Spacing.lg.rawValue)
        }
        .onAppear { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    }
}
