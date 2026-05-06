import Foundation

enum XPAwardEngine {
    @discardableResult
    static func apply(category: ActivityCategory, minutes: Double, player: Player, goalCategory: StatCategory?) -> (xp: Int, stats: [StatCategory]) {
        let base = max(1, Int(minutes.rounded()))
        switch category {
        case .training:
            apply(delta: Int(Double(base) * 0.7), to: .strength, player: player)
            apply(delta: Int(Double(base) * 0.3), to: .vitality, player: player)
            return (base, [.strength, .vitality])
        case .recovery:
            apply(delta: Int(Double(base) * 0.8), to: .vitality, player: player)
            apply(delta: Int(Double(base) * 0.2), to: .discipline, player: player)
            return (base, [.vitality, .discipline])
        case .cognition:
            apply(delta: base, to: .intelligence, player: player)
            return (base, [.intelligence])
        case .maintenance:
            apply(delta: max(1, base / 4), to: .discipline, player: player)
            return (max(1, base / 4), [.discipline])
        case .social:
            let value = max(1, base / 5)
            apply(delta: value, to: .discipline, player: player)
            apply(delta: value, to: .vitality, player: player)
            return (value * 2, [.discipline, .vitality])
        case .distraction:
            apply(delta: -max(2, base / 3), to: .discipline, player: player)
            return (-max(2, base / 3), [.discipline])
        case .declaredDistraction:
            apply(delta: -max(3, base / 2), to: .discipline, player: player)
            return (-max(3, base / 2), [.discipline])
        case .declaredGoal:
            let stat = goalCategory ?? .discipline
            apply(delta: base, to: stat, player: player)
            return (base, [stat])
        case .unknown:
            return (0, [])
        }
    }

    private static func apply(delta: Int, to stat: StatCategory, player: Player) {
        guard delta != 0 else { return }
        switch stat {
        case .intelligence:
            var block = player.intelligence
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.intelligence = block
        case .strength:
            var block = player.strength
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.strength = block
        case .vitality:
            var block = player.vitality
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.vitality = block
        case .discipline:
            var block = player.discipline
            block.currentXP = max(0, block.currentXP + delta)
            if delta > 0 { block.totalXP += delta }
            player.discipline = block
        }
        player.totalXP = max(0, player.totalXP + delta)
    }
}
