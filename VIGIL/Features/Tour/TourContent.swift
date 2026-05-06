import Foundation

struct TourContent {
    let title: String
    let body: String
}

enum TourContentRegistry {
    static func content(for id: TourID) -> TourContent {
        switch id {
        case .dashboard:
            return TourContent(
                title: "DASHBOARD",
                body: """
[SYSTEM BRIEFING]
This is your dashboard.
Vital signs. XP flow. Daily directives.
Read the data. Act on it. The system is watching.
"""
            )
        case .questBoard:
            return TourContent(
                title: "QUESTS",
                body: """
[SYSTEM BRIEFING]
Quests are issued, not chosen.
Some daily. Some unexpected. Some unforgiving.
Failure is logged permanently.
"""
            )
        case .profile:
            return TourContent(
                title: "PROFILE",
                body: """
[SYSTEM BRIEFING]
Your record. Your rank. Your titles.
Stats reflect input. Not intent.
The system judges what you do, not what you plan.
"""
            )
        case .timer:
            return TourContent(
                title: "TIMER",
                body: """
[SYSTEM BRIEFING]
A focus contract.
Start it. Do not break it.
Closing the app does not stop the system.
"""
            )
        case .systemLog:
            return TourContent(
                title: "SYSTEM LOG",
                body: """
[SYSTEM BRIEFING]
Every verdict. Every reward. Every punishment.
The system forgets nothing.
Read it when you forget who you are.
"""
            )
        case .settings:
            return TourContent(
                title: "SETTINGS",
                body: """
[SYSTEM BRIEFING]
Limited controls.
The contract terms cannot be renegotiated.
Reset the system only if you intend to begin again.
"""
            )
        }
    }
}
