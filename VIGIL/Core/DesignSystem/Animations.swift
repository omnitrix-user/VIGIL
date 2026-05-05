//
//  Animations.swift
//  VIGIL
//

import SwiftUI
import UIKit

enum VIGILAnimations {
    static let standardEaseInOutDuration: TimeInterval = 0.35

    static var standardEaseInOut: Animation {
        if vigilReduceMotionEnabled() {
            return .easeInOut(duration: min(standardEaseInOutDuration, 0.2))
        }
        return .easeInOut(duration: standardEaseInOutDuration)
    }
}

/// Matches `.cursorrules` sections 18 and 31 — use before playing non–Reduce Motion alternatives.
func vigilReduceMotionEnabled() -> Bool {
    UIAccessibility.isReduceMotionEnabled
}
