import Foundation

enum WeaknessCascadePhase: String, Codable, CaseIterable {
    case source
    case frequency
    case duration
    case verdict
    case cap
}

struct PartialDeclaredDistraction: Codable, Hashable {
    var weakness: Weakness
    var source: String = ""
    var frequency: String = "Daily"
    var durationMinutes: Double = 60
    var verdict: VerdictOption = .trackOnly
    var capValue: Double? = nil
}

struct WeaknessCascadeCoordinator: Codable {
    var weaknesses: [Weakness] = []
    var currentIndex: Int = 0
    var phase: WeaknessCascadePhase = .source
    var inProgress: PartialDeclaredDistraction?
    var completed: [DeclaredDistraction] = []
    var drafts: [Weakness: PartialDeclaredDistraction] = [:]

    var isReady: Bool { !weaknesses.isEmpty }

    var currentWeakness: Weakness? {
        guard currentIndex >= 0, currentIndex < weaknesses.count else { return nil }
        return weaknesses[currentIndex]
    }

    var progressHeader: String {
        "[WEAKNESS \(currentIndex + 1) OF \(max(weaknesses.count, 1))]"
    }

    mutating func start(with selected: [Weakness]) {
        weaknesses = selected
        currentIndex = 0
        phase = .source
        completed = []
        if let first = selected.first {
            inProgress = drafts[first] ?? PartialDeclaredDistraction(weakness: first)
            drafts[first] = inProgress
        } else {
            inProgress = nil
        }
    }

    mutating func syncDraft() {
        guard let weakness = currentWeakness, let inProgress else { return }
        drafts[weakness] = inProgress
    }

    mutating func advance() -> Bool {
        guard var current = inProgress else { return false }
        switch phase {
        case .source:
            phase = .frequency
            return false
        case .frequency:
            phase = .duration
            return false
        case .duration:
            phase = .verdict
            return false
        case .verdict:
            if current.verdict == .limit {
                phase = .cap
                return false
            }
            current.capValue = nil
            inProgress = current
            return finalizeCurrentWeakness()
        case .cap:
            return finalizeCurrentWeakness()
        }
    }

    mutating func back() {
        switch phase {
        case .source:
            guard currentIndex > 0 else { return }
            currentIndex -= 1
            let weakness = weaknesses[currentIndex]
            let draft = drafts[weakness] ?? PartialDeclaredDistraction(weakness: weakness)
            inProgress = draft
            phase = draft.verdict == .limit ? .cap : .verdict
        case .frequency:
            phase = .source
        case .duration:
            phase = .frequency
        case .verdict:
            phase = .duration
        case .cap:
            phase = .verdict
        }
    }

    mutating func update(_ draft: PartialDeclaredDistraction) {
        inProgress = draft
        syncDraft()
    }

    private mutating func finalizeCurrentWeakness() -> Bool {
        guard let current = inProgress else { return false }
        let declared = DeclaredDistraction(
            name: current.weakness.rawValue,
            source: current.source,
            frequency: current.frequency,
            durationMinutes: current.durationMinutes,
            verdict: current.verdict,
            capValue: current.verdict == .limit ? current.capValue : nil
        )
        completed.removeAll { $0.name == declared.name }
        completed.append(declared)
        syncDraft()

        if currentIndex < weaknesses.count - 1 {
            currentIndex += 1
            let nextWeakness = weaknesses[currentIndex]
            let nextDraft = drafts[nextWeakness] ?? PartialDeclaredDistraction(weakness: nextWeakness)
            inProgress = nextDraft
            phase = .source
            return false
        }
        return true
    }
}
