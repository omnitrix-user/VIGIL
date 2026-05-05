//
//  StatBlock.swift
//  VIGIL
//

import Foundation

struct StatBlock: Codable {
    var currentXP: Int
    var totalXP: Int
    var level: Int
    var xpToNextLevel: Int
    var debuffActive: Bool
    var debuffExpiresAt: Date?
    var weekHistory: [Int]
}
