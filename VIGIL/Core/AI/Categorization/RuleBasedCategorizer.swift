import Foundation

struct RuleBasedCategorizer: ActivityCategorizing {
    func categorize(
        _ batch: [ActivityEvent],
        playerContext: PlayerCategorizationContext
    ) async throws -> [CategorizedActivity] {
        batch.map { event in
            let lowerName = event.name.lowercased()

            if let declared = playerContext.declaredDistractions.first(where: { lowerName.contains($0.name.lowercased()) }) {
                return CategorizedActivity(
                    activityId: event.id,
                    category: .declaredDistraction,
                    confidence: 0.95,
                    reasoning: "Matches declared distraction \(declared.name)"
                )
            }

            if let goal = playerContext.declaredGoals.first(where: { lowerName.contains($0.name.lowercased()) }) {
                return CategorizedActivity(
                    activityId: event.id,
                    category: .declaredGoal,
                    confidence: 0.92,
                    reasoning: "Matches declared goal \(goal.name)"
                )
            }

            if event.source == .healthKitCategory && event.identifier == "sleepAnalysis" {
                return CategorizedActivity(activityId: event.id, category: .recovery, confidence: 0.9, reasoning: "Sleep category event")
            }
            if event.source == .healthKitCategory && event.identifier == "mindfulSession" {
                return CategorizedActivity(activityId: event.id, category: .recovery, confidence: 0.9, reasoning: "Mindful session event")
            }

            if trainingWorkoutIdentifiers.contains(event.identifier) {
                return CategorizedActivity(activityId: event.id, category: .training, confidence: 0.86, reasoning: "Training workout type")
            }
            if distractionBundleIDs.contains(event.identifier) {
                return CategorizedActivity(activityId: event.id, category: .distraction, confidence: 0.86, reasoning: "Known distraction app")
            }
            if cognitionBundleIDs.contains(event.identifier) {
                return CategorizedActivity(activityId: event.id, category: .cognition, confidence: 0.83, reasoning: "Known cognition app")
            }
            if event.identifier == "phone_call", event.durationMinutes > 5 {
                return CategorizedActivity(activityId: event.id, category: .social, confidence: 0.8, reasoning: "Phone call over five minutes")
            }
            return CategorizedActivity(activityId: event.id, category: .unknown, confidence: 0.5, reasoning: "No matching declared or default rule")
        }
    }

    private var trainingWorkoutIdentifiers: Set<String> {
        [
            "running",
            "traditionalStrengthTraining",
            "functionalStrengthTraining",
            "highIntensityIntervalTraining",
            "cycling",
            "swimming",
            "yoga",
            "walking",
            "hiking",
            "elliptical",
            "rowing",
            "pilates",
            "stairClimbing",
            "dance",
        ]
    }

    private var distractionBundleIDs: Set<String> {
        [
            "com.instagram",
            "com.burbn.instagram",
            "com.tiktok",
            "com.zhiliaoapp.musically",
            "com.facebook",
            "com.toyopagroup.picaboo",
            "com.google.ios.youtube",
        ]
    }

    private var cognitionBundleIDs: Set<String> {
        [
            "com.apple.mobilenotes",
            "com.tinrobots",
            "com.apple.Pages",
            "com.apple.Keynote",
            "com.apple.Numbers",
            "com.apple.iWork.Pages",
            "com.apple.reminders",
        ]
    }
}
