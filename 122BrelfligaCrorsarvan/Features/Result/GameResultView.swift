//
//  GameResultView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct GameResultView: View {
    let outcome: GameOutcome
    let onLevels: () -> Void
    let onRetry: () -> Void
    let onNext: () -> Void

    @State private var starAnimations: [Bool] = [false, false, false]
    @State private var showBanner = false
    @State private var showRankBanner = false

    var body: some View {
        ZStack(alignment: .top) {
            AppScreenBackground()
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    Text(outcome.stars > 0 ? "Stage complete" : "Keep trying")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    starsRow

                    if outcome.stars > 0, outcome.totalPointsThisRound > 0 {
                        skillPointsSection
                    } else if outcome.stars == 0 {
                        Text("Win streak reset — come back stronger.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        statLine(title: "Time", value: "\(outcome.seconds)s")
                        statLine(title: "Accuracy", value: "\(outcome.accuracyPercent)%")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCardSoft(cornerRadius: AppStyle.cardRadius)

                    VStack(spacing: 12) {
                        if canAdvance {
                            PrimaryButton(title: "Next stage") {
                                onNext()
                            }
                        }
                        SecondaryButton(title: "Retry") {
                            onRetry()
                        }
                        SecondaryButton(title: "Levels") {
                            onLevels()
                        }
                    }
                }
                .padding(16)
            }

            VStack(spacing: 10) {
                if showRankBanner, let rank = outcome.promotedRank {
                    rankUpBanner(rank: rank)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if showBanner, let first = outcome.newAchievements.first {
                    achievementBanner(for: first)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 12)
        }
        .onAppear {
            animateStars()
            if !outcome.newAchievements.isEmpty {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.2)) {
                    showBanner = true
                }
            }
            if outcome.promotedRank != nil {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.45)) {
                    showRankBanner = true
                }
            }
        }
    }

    private var canAdvance: Bool {
        outcome.stars > 0 && outcome.level < LevelBalance.stagesPerActivity
    }

    private var skillPointsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.appAccent)
                Text("Skill Points earned")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }
            HStack {
                Text("Base reward")
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text("+\(outcome.skillPointsGained)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
            }
            if outcome.streakBonusPoints > 0 {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color.appPrimary)
                        Text("Streak bonus")
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    Spacer()
                    Text("+\(outcome.streakBonusPoints)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            Divider().background(Color.appTextSecondary.opacity(0.25))
            HStack {
                Text("Total this round")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text("+\(outcome.totalPointsThisRound)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardElevated(cornerRadius: AppStyle.cardRadius)
    }

    private var starsRow: some View {
        HStack(spacing: 18) {
            ForEach(0..<3, id: \.self) { index in
                let filled = index < outcome.stars
                Image(systemName: filled ? "star.fill" : "star")
                    .font(.system(size: 40))
                    .foregroundStyle(filled ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                    .shadow(color: filled && starAnimations[index] ? Color.appAccent.opacity(0.65) : .clear, radius: 10)
                    .scaleEffect(filled ? (starAnimations[index] ? 1 : 0.35) : 1)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.55)
                            .delay(Double(index) * 0.15),
                        value: starAnimations[index]
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func animateStars() {
        starAnimations = [false, false, false]
        for index in 0..<min(outcome.stars, 3) {
            let delay = Double(index) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    starAnimations[index] = true
                }
            }
        }
    }

    private func statLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func achievementBanner(for achievement: AchievementID) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(Color.appPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(achievement.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
        .padding(14)
        .appFloatingPanel(cornerRadius: AppStyle.panelRadius)
        .padding(.horizontal, 16)
    }

    private func rankUpBanner(rank: PlayerRank) -> some View {
        HStack(spacing: 12) {
            Image(systemName: rank.symbolName)
                .font(.title2)
                .foregroundStyle(Color.appAccent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Rank up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(rank.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
            }
            Spacer()
        }
        .padding(14)
        .appFloatingPanel(cornerRadius: AppStyle.panelRadius)
        .padding(.horizontal, 16)
    }
}
