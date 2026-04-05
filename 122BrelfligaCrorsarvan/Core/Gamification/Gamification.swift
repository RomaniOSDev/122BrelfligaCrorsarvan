//
//  Gamification.swift
//  122BrelfligaCrorsarvan
//

import Foundation

/// Skill Points — progression currency (not coins or purchases).
enum PlayerRank: Int, CaseIterable, Comparable, Hashable {
    case scout = 0
    case trainee
    case specialist
    case elite
    case master
    case legend

    var title: String {
        switch self {
        case .scout: return "Scout"
        case .trainee: return "Trainee"
        case .specialist: return "Specialist"
        case .elite: return "Elite"
        case .master: return "Master"
        case .legend: return "Legend"
        }
    }

    var detail: String {
        switch self {
        case .scout: return "Just getting warmed up."
        case .trainee: return "Solid rhythm across stages."
        case .specialist: return "Sharp focus and clean runs."
        case .elite: return "Few can match this pace."
        case .master: return "Top-tier control and timing."
        case .legend: return "The bar is yours."
        }
    }

    var symbolName: String {
        switch self {
        case .scout: return "leaf.fill"
        case .trainee: return "figure.walk"
        case .specialist: return "scope"
        case .elite: return "bolt.fill"
        case .master: return "crown.fill"
        case .legend: return "star.circle.fill"
        }
    }

    /// Minimum total skill points to reach this rank.
    var minSkillPoints: Int {
        switch self {
        case .scout: return 0
        case .trainee: return 350
        case .specialist: return 1_000
        case .elite: return 2_400
        case .master: return 4_500
        case .legend: return 8_000
        }
    }

    static func rank(for totalPoints: Int) -> PlayerRank {
        let ordered = PlayerRank.allCases.reversed()
        return ordered.first { totalPoints >= $0.minSkillPoints } ?? .scout
    }

    var next: PlayerRank? {
        PlayerRank(rawValue: rawValue + 1)
    }

    static func < (lhs: PlayerRank, rhs: PlayerRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum SkillPointsCalculator {
    /// Base + difficulty + star tier; only for successful clears (stars > 0).
    static func basePoints(level: Int, stars: Int, difficulty: Difficulty) -> Int {
        guard stars > 0 else { return 0 }
        let stage = 12 + level * 3
        let starMult: Double = stars == 3 ? 1.85 : stars == 2 ? 1.4 : 1.05
        let diffMult: Double
        switch difficulty {
        case .easy: diffMult = 1.0
        case .normal: diffMult = 1.14
        case .hard: diffMult = 1.32
        }
        return max(8, Int(Double(stage) * starMult * diffMult))
    }

    /// Extra points from win streak (after this clear is counted).
    static func streakBonusPoints(newWinStreak: Int) -> Int {
        guard newWinStreak >= 3 else { return 0 }
        let extra = (newWinStreak - 2) * 6
        return min(48, extra)
    }
}

struct StageRewardOutcome {
    let newAchievements: [AchievementID]
    let skillPointsGained: Int
    let streakBonusPoints: Int
    let rankBefore: PlayerRank
    let rankAfter: PlayerRank
    let winStreak: Int
    let dailyStreak: Int

    var rankUp: Bool {
        rankAfter > rankBefore
    }

    var totalPointsThisRound: Int {
        skillPointsGained + streakBonusPoints
    }
}

extension PlayerRank {
    /// Progress 0...1 toward the next rank; 1 if already at Legend cap for display.
    static func progressBar(totalPoints: Int) -> (tier: PlayerRank, nextTier: PlayerRank?, fraction: Double) {
        let tier = PlayerRank.rank(for: totalPoints)
        guard let next = tier.next else {
            return (tier, nil, 1)
        }
        let span = next.minSkillPoints - tier.minSkillPoints
        guard span > 0 else { return (tier, next, 1) }
        let p = Double(totalPoints - tier.minSkillPoints) / Double(span)
        return (tier, next, min(1, max(0, p)))
    }
}

extension GameOutcome {
    init(
        activity: ActivityKind,
        level: Int,
        stars: Int,
        seconds: Int,
        accuracyPercent: Int,
        reward: StageRewardOutcome
    ) {
        self.init(
            activity: activity,
            level: level,
            stars: stars,
            seconds: seconds,
            accuracyPercent: accuracyPercent,
            newAchievements: reward.newAchievements,
            skillPointsGained: reward.skillPointsGained,
            streakBonusPoints: reward.streakBonusPoints,
            promotedRank: reward.rankUp ? reward.rankAfter : nil
        )
    }
}
