//
//  VIGILEnums.swift
//  VIGIL
//

import Foundation

enum Rank: String, CaseIterable, Codable {
    case E, D, C, B, A, S, SS, SSS
}

enum StatCategory: String, Codable {
    case intelligence, strength, vitality, discipline
}

enum GoalType: String, Codable {
    case duration
    case count
    case boolean
}

enum VerdictOption: String, Codable {
    case limit
    case eliminate
    case replace
    case trackOnly
}

enum QuestType: String, Codable {
    case shadow
    case ascension
    case reckoning
    case awakening
}

enum QuestStatus: String, Codable {
    case active, completed, failed, expired
}

enum VerdictType: String, Codable {
    case reward, punishment, warning, observation
    case weeklyReview, monthlyReview
}

enum ConsequenceType: String, Codable {
    case xpLoss
    case statDebuff
    case titleStripped
    case streakReset
    case rankDemotion
    case shamePost
    case questIssued
    case nuclear
}

enum VerificationMethod: String, Codable {
    case healthKit
    case screenTime
    case timer
    case manual
    case ai
}

enum SleepQuality: String, Codable {
    case poor, fair, good, excellent
}
