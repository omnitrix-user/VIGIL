//
//  BootSequenceView.swift
//  VIGIL
//

import SwiftUI

struct BootSequenceView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    private var reduceMotion: Bool {
        accessibilityReduceMotion || vigilReduceMotionEnabled()
    }

    @State private var timelineStart = Date()

    private let letters = Array("VIGIL")
    private let taglineText = "The system is watching."
    private let titlePhaseStart: Double = 0.8
    private let titlePhaseEnd: Double = 1.8
    private let taglineFadeStart: Double = 1.8
    private let taglineFadeEnd: Double = 2.5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(timelineStart)

            ZStack {
                Color.bg.primary
                    .ignoresSafeArea()

                bootContent(elapsed: elapsed)
            }
        }
        .transition(.opacity)
        .preferredColorScheme(.dark)
        .task {
            try? await Task.sleep(for: .milliseconds(2500))
            onComplete()
        }
    }

    @ViewBuilder
    private func bootContent(elapsed: Double) -> some View {
        VStack(spacing: Spacing.xl.rawValue) {
            eyeFrame(elapsed: elapsed)
            titleFrame(elapsed: elapsed)
            taglineFrame(elapsed: elapsed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func eyeFrame(elapsed: Double) -> some View {
        let pulse = eyePulseAmount(elapsed: elapsed)
        let scale = CGFloat(pulse.scale)
        let opacity = pulse.opacity

        return Image(systemName: "eye.fill")
            .font(.system(size: 56))
            .foregroundStyle(Color.accent.primary)
            .scaleEffect(scale)
            .opacity(opacity)
            .accessibilityHidden(true)
    }

    private func eyePulseAmount(elapsed: Double) -> (scale: Double, opacity: Double) {
        if reduceMotion {
            let linear = min(1, elapsed / titlePhaseStart)
            return (scale: linear, opacity: linear)
        }
        if elapsed >= titlePhaseStart {
            return (scale: 1, opacity: 1)
        }
        let linear = elapsed / titlePhaseStart
        let wobble = 1 + 0.045 * sin(elapsed * 16)
        let scale = min(1, linear * wobble)
        return (scale: scale, opacity: linear)
    }

    private func titleFrame(elapsed: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(Font.vigil.display)
                    .foregroundStyle(Color.text.primary)
                    .fixedSize()
                    .opacity(letterOpacity(elapsed: elapsed, index: index))
            }
        }
        .accessibilityHidden(true)
    }

    private func letterOpacity(elapsed: Double, index: Int) -> Double {
        if reduceMotion {
            return elapsed >= titlePhaseStart + 0.04 ? 1 : 0
        }
        let step: Double = 0.2
        let reveal = titlePhaseStart + step * Double(index)
        let appearWindow = step * 0.55
        return ((elapsed - reveal) / appearWindow).vigilClamped(to: 0...1)
    }

    private func taglineFrame(elapsed: Double) -> some View {
        let opacity: Double
        if reduceMotion {
            opacity = elapsed >= taglineFadeStart + 0.04 ? 1 : 0
        } else {
            opacity = ((elapsed - taglineFadeStart) / (taglineFadeEnd - taglineFadeStart))
                .vigilClamped(to: 0...1)
        }

        return Text(taglineText)
            .font(Font.vigil.headline)
            .foregroundStyle(Color.text.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(opacity)
            .accessibilityHidden(true)
    }
}

private extension Double {
    func vigilClamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
