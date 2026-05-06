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

    enum Morning {
        static let variants = [
            "Player. New cycle. The system has prepared your task.",
            "Day [N]. One directive issued. Find it.",
            "Morning. The work continues. The system is watching.",
        ]
    }

    enum Idle18h {
        static let variants = [
            "Eighteen hours of silence. The system notices.",
            "Absence logged. Resume.",
            "The clock has not stopped. You did.",
        ]
    }

    enum Idle48h {
        static let variants = [
            "Discipline does not pause. You did.",
            "Two days lost. They cannot be reclaimed.",
            "The system held your slot. Return.",
        ]
    }

    enum Idle7d {
        static let variants = [
            "Re-entry required. Your record remains.",
            "Seven days. The system remembers everything.",
            "You walked away. The system did not.",
        ]
    }
}
