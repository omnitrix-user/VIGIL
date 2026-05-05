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
        static let display: Font = .system(size: 48, weight: .black, design: .rounded)

        static let titleLarge: Font = .system(size: 34, weight: .bold, design: .default)

        static let title: Font = .system(size: 28, weight: .semibold, design: .default)

        static let headline: Font = .system(size: 17, weight: .semibold, design: .default)

        static let body: Font = .system(size: 15, weight: .regular, design: .default)

        static let caption: Font = .system(size: 12, weight: .regular, design: .monospaced)

        static let system: Font = .system(size: 14, weight: .medium, design: .monospaced)
    }
}
