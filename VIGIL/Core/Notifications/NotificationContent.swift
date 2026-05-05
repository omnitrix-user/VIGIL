//
//  NotificationContent.swift
//  VIGIL
//

import Foundation

/// Centralized notification copy (see `.cursorrules`).
enum NotificationContent {
    enum BlockViolation {
        static let title = "Violation Detected"
        static let body = "Discipline XP deducted. The system has noted this."
    }

    /// First strike during a block (grace elapsed): cold warning, no XP deduction yet.
    enum BlockViolationWarning {
        static let title = "Violation Detected"
        static let body = "Close your phone. The next breach will cost you."
    }
}
