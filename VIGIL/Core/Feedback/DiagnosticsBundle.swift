import Foundation

struct PlayerAnonymizedSnapshot: Codable {
    let currentRank: String
    let totalXP: Int
    let daysActive: Int
    let streakLength: Int
    let intelligenceXP: Int
    let strengthXP: Int
    let vitalityXP: Int
    let disciplineXP: Int
}

struct DiagnosticsBundle: Codable {
    let appVersion: String
    let buildNumber: String
    let iOSVersion: String
    let deviceModel: String
    let lastFiftyLogLines: [String]
    let playerSnapshot: PlayerAnonymizedSnapshot
    let lastFiveSystemMessages: [String]

    func formatForEmail() -> String {
        [
            "APP VERSION: \(appVersion) (\(buildNumber))",
            "IOS VERSION: \(iOSVersion)",
            "DEVICE: \(deviceModel)",
            "PLAYER SNAPSHOT: RANK \(playerSnapshot.currentRank), XP \(playerSnapshot.totalXP), DAYS \(playerSnapshot.daysActive), STREAK \(playerSnapshot.streakLength)",
            "STAT XP: INT \(playerSnapshot.intelligenceXP), STR \(playerSnapshot.strengthXP), VIT \(playerSnapshot.vitalityXP), DISC \(playerSnapshot.disciplineXP)",
            "LAST 5 SYSTEM MESSAGES:",
            lastFiveSystemMessages.joined(separator: "\n"),
            "LAST 50 LOG LINES:",
            lastFiftyLogLines.joined(separator: "\n"),
        ].joined(separator: "\n\n")
    }
}
