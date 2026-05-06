//
//  Typography.swift
//  VIGIL
//
//  Fixed semantic sizes only (no text styles). Pair `Text` with `.fixedSize(...)`
//  where SwiftUI still attempts to adapt layout — VIGIL does not support Dynamic Type.
//

import SwiftUI

extension Font {
    enum vigil {
        static let display: Font = .custom("Orbitron", size: 48, relativeTo: .largeTitle)

        static let titleLarge: Font = .system(size: 28, weight: .bold, design: .monospaced)

        static let title: Font = .system(size: 22, weight: .bold, design: .monospaced)

        static let headline: Font = .system(size: 17, weight: .semibold, design: .monospaced)

        static let body: Font = .system(size: 14, weight: .regular, design: .monospaced)

        static let caption: Font = .system(size: 11, weight: .regular, design: .monospaced)

        static let system: Font = .system(size: 13, weight: .medium, design: .monospaced)

        /// Goal session countdown / elapsed digits (dashboard timer).
        static let timerDigits: Font = .system(size: 26, weight: .semibold, design: .monospaced)

        /// Apply with `.tracking(Font.vigil.displayTracking)` on display text.
        static let displayTracking: CGFloat = -2
    }
}
