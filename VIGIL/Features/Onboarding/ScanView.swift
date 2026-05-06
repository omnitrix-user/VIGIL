//
//  ScanView.swift
//  VIGIL
//

import SwiftUI
import UIKit

struct ScanView: View {
    @State private var progress: Double = 0
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg.rawValue) {
            Spacer()
            Text("Unknown entity detected...")
                .font(Font.vigil.title)
                .foregroundStyle(Color.text.primary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                ProgressView(value: progress)
                    .tint(Color.accent.primary)
                Text("System scan in progress")
                    .font(Font.vigil.system)
                    .foregroundStyle(Color.text.secondary)
            }
            .padding(.horizontal, Spacing.lg.rawValue)
            Spacer()
        }
        .background(Color.bg.primary.ignoresSafeArea())
        .task {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.linear(duration: 2.4)) {
                progress = 1
            }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            onDone()
        }
    }
}
