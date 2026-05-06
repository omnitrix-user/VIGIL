//
//  Colors.swift
//  VIGIL
//

import SwiftUI

extension Color {
    private static func vigilHex(_ hex: UInt32, alpha: Double = 1) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    enum bg {
        static let primary = Color.vigilHex(0x000000)
        static let secondary = Color.vigilHex(0x0A0A14)
        static let tertiary = Color.vigilHex(0x0E0E1E)
    }

    enum accent {
        static let primary = Color.vigilHex(0x6C63FF)
        static let secondary = Color.vigilHex(0xA78BFA)
        static let gold = Color.vigilHex(0xF59E0B)
        static let electric = Color.vigilHex(0x3B82F6)
    }

    enum status {
        static let danger = Color.vigilHex(0xEF4444)
        static let success = Color.vigilHex(0x22C55E)
        static let warning = Color.vigilHex(0xF97316)
    }

    enum text {
        static let primary = Color.vigilHex(0xE2E8F0)
        static let secondary = Color.vigilHex(0x94A3B8)
        static let muted = Color.vigilHex(0x64748B)
    }

    enum scanline {
        static let color = Color.vigilHex(0x6C63FF, alpha: 0.04)
    }

    enum rank {
        static let E = Color.vigilHex(0x4B5563)
        static let D = Color.vigilHex(0x1D4ED8)
        static let C = Color.vigilHex(0x7C3AED)
        static let B = Color.vigilHex(0x6D28D9)
        static let A = Color.vigilHex(0x4C1D95)
        static let S = Color.vigilHex(0xF59E0B)
        static let SS = Color.vigilHex(0xD97706)
        /// Base colour for SSS rank; animated treatment is applied in views.
        static let SSS = Color.vigilHex(0x6C63FF)
    }
}
