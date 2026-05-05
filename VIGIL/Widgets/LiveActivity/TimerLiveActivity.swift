//
//  TimerLiveActivity.swift
//  VIGIL
//
//  ActivityKit attributes + stop intent. Custom Live Activity chrome requires a Widget Extension target;
//  the main app still posts updates so lock screen / Dynamic Island use system presentation for the activity.
//

import ActivityKit
import AppIntents

struct VigilTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var isPaused: Bool
        var capWarningLine: String
    }

    var goalName: String
    var goalId: UUID
}

@available(iOS 17.0, *)
struct VigilStopTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "STOP"
    static var description = IntentDescription("End the active goal session.")

    func perform() async throws -> some IntentResult {
        await GoalTimerManager.shared.liveActivityStopIntentRequested()
        return .result()
    }
}
