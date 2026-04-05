//
//  GameModels.swift
//  122BrelfligaCrorsarvan
//

import Foundation

enum LevelBalance {
    /// Total playable stages per activity (Easy + Normal + Hard).
    static let stagesPerActivity = 24

    static var maxStarsPerActivity: Int { stagesPerActivity * 3 }
}

enum ActivityKind: String, CaseIterable, Identifiable, Codable {
    case shapeShifter
    case colorDash
    case sequenceQuest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shapeShifter: return "Shape Shifter"
        case .colorDash: return "Color Dash"
        case .sequenceQuest: return "Sequence Quest"
        }
    }

    var subtitle: String {
        switch self {
        case .shapeShifter:
            return "Drag shapes onto matching outlines."
        case .colorDash:
            return "Tap the color that matches the target."
        case .sequenceQuest:
            return "Watch the pattern, then repeat it in order."
        }
    }

    var symbolName: String {
        switch self {
        case .shapeShifter: return "square.on.circle"
        case .colorDash: return "paintpalette.fill"
        case .sequenceQuest: return "list.number"
        }
    }
}

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }

    func levelRange() -> ClosedRange<Int> {
        let n = LevelBalance.stagesPerActivity / 3
        switch self {
        case .easy: return 1...n
        case .normal: return (n + 1)...(2 * n)
        case .hard: return (2 * n + 1)...LevelBalance.stagesPerActivity
        }
    }

    static func difficulty(forLevel level: Int) -> Difficulty {
        let n = LevelBalance.stagesPerActivity / 3
        switch level {
        case 1...n: return .easy
        case (n + 1)...(2 * n): return .normal
        default: return .hard
        }
    }
}

struct LevelIdentifier: Hashable, Codable {
    let activity: ActivityKind
    let level: Int

    var storageKey: String {
        "\(activity.rawValue)_\(level)"
    }
}

enum AchievementID: String, CaseIterable, Identifiable {
    case firstFinish
    case starCollector
    case shapeComplete
    case colorComplete
    case sequenceComplete
    case marathon
    case hotStreak
    case weekWarrior
    case pointHunter
    case starLegend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstFinish: return "First Finish"
        case .starCollector: return "Star Collector"
        case .shapeComplete: return "Shape Path"
        case .colorComplete: return "Color Path"
        case .sequenceComplete: return "Sequence Path"
        case .marathon: return "Marathon"
        case .hotStreak: return "On Fire"
        case .weekWarrior: return "Week Warrior"
        case .pointHunter: return "Point Hunter"
        case .starLegend: return "Star Legend"
        }
    }

    var detail: String {
        switch self {
        case .firstFinish: return "Complete any stage once."
        case .starCollector: return "Earn three stars on any stage."
        case .shapeComplete: return "Clear every Shape Shifter stage."
        case .colorComplete: return "Clear every Color Dash stage."
        case .sequenceComplete: return "Clear every Sequence Quest stage."
        case .marathon: return "Play for at least one hour in total."
        case .hotStreak: return "Reach a five-stage win streak."
        case .weekWarrior: return "Keep a seven-day activity streak."
        case .pointHunter: return "Earn 3,000 Skill Points in total."
        case .starLegend: return "Collect three stars on 45 different stages."
        }
    }
}

struct GameOutcome: Identifiable, Hashable {
    let id: UUID
    let activity: ActivityKind
    let level: Int
    let stars: Int
    let seconds: Int
    let accuracyPercent: Int
    let newAchievements: [AchievementID]
    let skillPointsGained: Int
    let streakBonusPoints: Int
    let promotedRank: PlayerRank?

    init(
        activity: ActivityKind,
        level: Int,
        stars: Int,
        seconds: Int,
        accuracyPercent: Int,
        newAchievements: [AchievementID],
        skillPointsGained: Int,
        streakBonusPoints: Int,
        promotedRank: PlayerRank?
    ) {
        id = UUID()
        self.activity = activity
        self.level = level
        self.stars = stars
        self.seconds = seconds
        self.accuracyPercent = accuracyPercent
        self.newAchievements = newAchievements
        self.skillPointsGained = skillPointsGained
        self.streakBonusPoints = streakBonusPoints
        self.promotedRank = promotedRank
    }

    var totalPointsThisRound: Int {
        skillPointsGained + streakBonusPoints
    }
}
