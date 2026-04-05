//
//  AppStorage.swift
//  122BrelfligaCrorsarvan
//

import Combine
import Foundation

extension Notification.Name {
    static let progressDidReset = Notification.Name("bc.progressDidReset")
}

@MainActor
final class GameProgressStore: ObservableObject {
    private let defaults: UserDefaults
    private let prefix = "bc_"

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var totalPlaySeconds: Int
    @Published private(set) var activitiesFinished: Int
    @Published private(set) var totalSkillPoints: Int
    @Published private(set) var consecutiveWins: Int
    @Published private(set) var dailyStreak: Int

    private var starCache: [String: Int] = [:]
    private var unlockedCache: [String: Bool] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasSeenOnboarding = defaults.bool(forKey: Self.keyOnboarding(prefix))
        totalPlaySeconds = defaults.integer(forKey: Self.keyPlaySeconds(prefix))
        activitiesFinished = defaults.integer(forKey: Self.keyActivitiesFinished(prefix))
        totalSkillPoints = defaults.integer(forKey: Self.keySkillPoints(prefix))
        consecutiveWins = defaults.integer(forKey: Self.keyWinStreak(prefix))
        dailyStreak = defaults.integer(forKey: Self.keyDailyStreak(prefix))
        loadCaches()
    }

    private func loadCaches() {
        starCache.removeAll()
        unlockedCache.removeAll()
        for activity in ActivityKind.allCases {
            for level in 1...LevelBalance.stagesPerActivity {
                let id = LevelIdentifier(activity: activity, level: level)
                starCache[id.storageKey] = starsFromDefaults(for: id)
                unlockedCache[id.storageKey] = unlockedFromDefaults(for: id)
            }
        }
    }

    private static func keyOnboarding(_ p: String) -> String { "\(p)hasSeenOnboarding" }
    private static func keyPlaySeconds(_ p: String) -> String { "\(p)totalPlaySeconds" }
    private static func keyActivitiesFinished(_ p: String) -> String { "\(p)activitiesFinished" }
    private static func keySkillPoints(_ p: String) -> String { "\(p)totalSkillPoints" }
    private static func keyWinStreak(_ p: String) -> String { "\(p)consecutiveWins" }
    private static func keyDailyStreak(_ p: String) -> String { "\(p)dailyStreak" }
    private static func keyLastPlayDay(_ p: String) -> String { "\(p)lastPlayDayStart" }

    private func starsKey(_ id: LevelIdentifier) -> String { "\(prefix)stars_\(id.storageKey)" }
    private func unlockedKey(_ id: LevelIdentifier) -> String { "\(prefix)unlocked_\(id.storageKey)" }

    private func starsFromDefaults(for id: LevelIdentifier) -> Int {
        min(3, max(0, defaults.integer(forKey: starsKey(id))))
    }

    private func unlockedFromDefaults(for id: LevelIdentifier) -> Bool {
        if id.level == 1 { return true }
        return defaults.bool(forKey: unlockedKey(id))
    }

    func stars(for id: LevelIdentifier) -> Int {
        starCache[id.storageKey] ?? 0
    }

    func isUnlocked(_ id: LevelIdentifier) -> Bool {
        unlockedCache[id.storageKey] ?? (id.level == 1)
    }

    var clearedStagesCount: Int {
        ActivityKind.allCases.reduce(0) { partial, activity in
            partial + (1...LevelBalance.stagesPerActivity).filter { stars(for: LevelIdentifier(activity: activity, level: $0)) > 0 }.count
        }
    }

    var threeStarStagesCount: Int {
        ActivityKind.allCases.reduce(0) { partial, activity in
            partial + (1...LevelBalance.stagesPerActivity).filter {
                stars(for: LevelIdentifier(activity: activity, level: $0)) >= 3
            }.count
        }
    }

    var currentRank: PlayerRank {
        PlayerRank.rank(for: totalSkillPoints)
    }

    func setOnboardingFinished() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Self.keyOnboarding(prefix))
    }

    func registerActivityFinished() {
        activitiesFinished += 1
        defaults.set(activitiesFinished, forKey: Self.keyActivitiesFinished(prefix))
    }

    func addPlayTime(seconds: Int) {
        guard seconds > 0 else { return }
        totalPlaySeconds += seconds
        defaults.set(totalPlaySeconds, forKey: Self.keyPlaySeconds(prefix))
        objectWillChange.send()
    }

    func recordStageCompletion(
        activity: ActivityKind,
        level: Int,
        starsEarned: Int,
        durationSeconds: Int
    ) -> StageRewardOutcome {
        let id = LevelIdentifier(activity: activity, level: level)
        let before = Set(achievementsUnlocked())
        let rankBefore = PlayerRank.rank(for: totalSkillPoints)

        let previous = stars(for: id)
        let merged = max(previous, min(3, max(0, starsEarned)))
        starCache[id.storageKey] = merged
        defaults.set(merged, forKey: starsKey(id))

        if merged > 0, level < LevelBalance.stagesPerActivity {
            let next = LevelIdentifier(activity: activity, level: level + 1)
            unlockedCache[next.storageKey] = true
            defaults.set(true, forKey: unlockedKey(next))
        }

        addPlayTime(seconds: durationSeconds)

        var skillPoints = 0
        var streakBonus = 0
        var newWinStreak = consecutiveWins
        var newDaily = dailyStreak

        if merged == 0 {
            consecutiveWins = 0
            defaults.set(0, forKey: Self.keyWinStreak(prefix))
            objectWillChange.send()
            let afterFail = Set(achievementsUnlocked())
            return StageRewardOutcome(
                newAchievements: Array(afterFail.subtracting(before)),
                skillPointsGained: 0,
                streakBonusPoints: 0,
                rankBefore: rankBefore,
                rankAfter: rankBefore,
                winStreak: 0,
                dailyStreak: dailyStreak
            )
        }

        registerActivityFinished()

        let difficulty = Difficulty.difficulty(forLevel: level)
        skillPoints = SkillPointsCalculator.basePoints(level: level, stars: merged, difficulty: difficulty)

        newWinStreak = consecutiveWins + 1
        consecutiveWins = newWinStreak
        defaults.set(newWinStreak, forKey: Self.keyWinStreak(prefix))

        streakBonus = SkillPointsCalculator.streakBonusPoints(newWinStreak: newWinStreak)

        newDaily = updateDailyStreakAfterSuccess()
        dailyStreak = newDaily
        defaults.set(newDaily, forKey: Self.keyDailyStreak(prefix))

        let gained = skillPoints + streakBonus
        totalSkillPoints += gained
        defaults.set(totalSkillPoints, forKey: Self.keySkillPoints(prefix))

        let rankAfter = PlayerRank.rank(for: totalSkillPoints)

        let after = Set(achievementsUnlocked())
        return StageRewardOutcome(
            newAchievements: Array(after.subtracting(before)),
            skillPointsGained: skillPoints,
            streakBonusPoints: streakBonus,
            rankBefore: rankBefore,
            rankAfter: rankAfter,
            winStreak: newWinStreak,
            dailyStreak: newDaily
        )
    }

    private func updateDailyStreakAfterSuccess() -> Int {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let todayTs = todayStart.timeIntervalSince1970
        let raw = defaults.double(forKey: Self.keyLastPlayDay(prefix))

        if raw <= 0 {
            defaults.set(todayTs, forKey: Self.keyLastPlayDay(prefix))
            return 1
        }

        let lastDate = Date(timeIntervalSince1970: raw)
        let lastStart = cal.startOfDay(for: lastDate)
        let days = cal.dateComponents([.day], from: lastStart, to: todayStart).day ?? 0

        if days == 0 {
            return dailyStreak
        }
        if days == 1 {
            let next = dailyStreak + 1
            defaults.set(todayTs, forKey: Self.keyLastPlayDay(prefix))
            return next
        }
        defaults.set(todayTs, forKey: Self.keyLastPlayDay(prefix))
        return 1
    }

    func achievementsUnlocked() -> [AchievementID] {
        AchievementID.allCases.filter { isUnlocked($0) }
    }

    private func isUnlocked(_ achievement: AchievementID) -> Bool {
        switch achievement {
        case .firstFinish:
            return clearedStagesCount >= 1
        case .starCollector:
            return ActivityKind.allCases.contains { activity in
                (1...LevelBalance.stagesPerActivity).contains { stars(for: LevelIdentifier(activity: activity, level: $0)) >= 3 }
            }
        case .shapeComplete:
            return (1...LevelBalance.stagesPerActivity).allSatisfy { stars(for: LevelIdentifier(activity: .shapeShifter, level: $0)) > 0 }
        case .colorComplete:
            return (1...LevelBalance.stagesPerActivity).allSatisfy { stars(for: LevelIdentifier(activity: .colorDash, level: $0)) > 0 }
        case .sequenceComplete:
            return (1...LevelBalance.stagesPerActivity).allSatisfy { stars(for: LevelIdentifier(activity: .sequenceQuest, level: $0)) > 0 }
        case .marathon:
            return totalPlaySeconds >= 3600
        case .hotStreak:
            return consecutiveWins >= 5
        case .weekWarrior:
            return dailyStreak >= 7
        case .pointHunter:
            return totalSkillPoints >= 3000
        case .starLegend:
            return threeStarStagesCount >= 45
        }
    }

    func totalStars(for activity: ActivityKind) -> Int {
        (1...LevelBalance.stagesPerActivity).reduce(0) { $0 + stars(for: LevelIdentifier(activity: activity, level: $1)) }
    }

    func resetAllProgress() {
        let keys = defaults.dictionaryRepresentation().keys.filter { key in
            key.hasPrefix(prefix) && key != Self.keyOnboarding(prefix)
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
        totalPlaySeconds = 0
        activitiesFinished = 0
        totalSkillPoints = 0
        consecutiveWins = 0
        dailyStreak = 0
        defaults.set(0, forKey: Self.keyPlaySeconds(prefix))
        defaults.set(0, forKey: Self.keyActivitiesFinished(prefix))
        defaults.set(0, forKey: Self.keySkillPoints(prefix))
        defaults.set(0, forKey: Self.keyWinStreak(prefix))
        defaults.set(0, forKey: Self.keyDailyStreak(prefix))
        defaults.removeObject(forKey: Self.keyLastPlayDay(prefix))
        loadCaches()
        NotificationCenter.default.post(name: .progressDidReset, object: nil)
        objectWillChange.send()
    }
}
