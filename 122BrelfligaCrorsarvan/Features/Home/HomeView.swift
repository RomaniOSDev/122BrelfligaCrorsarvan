//
//  HomeView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                HomeHeroBanner(
                    clearedStages: store.clearedStagesCount,
                    totalStages: LevelBalance.stagesPerActivity * ActivityKind.allCases.count
                )
                .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 20) {
                    GamificationHeaderCard(
                        rank: store.currentRank,
                        totalPoints: store.totalSkillPoints,
                        winStreak: store.consecutiveWins,
                        dailyStreak: store.dailyStreak
                    )

                    HomeQuickStatsGrid()

                    sectionTitle(icon: "square.grid.2x2.fill", title: "Activities")

                    VStack(spacing: 12) {
                        ForEach(ActivityKind.allCases) { activity in
                            NavigationLink(value: activity) {
                                ActivityHomeCard(
                                    activity: activity,
                                    stars: store.totalStars(for: activity),
                                    maxStars: LevelBalance.maxStarsPerActivity
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .appScreenBackdrop()
        .navigationDestination(for: ActivityKind.self) { activity in
            GameLevelsView(activity: activity)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
        }
        .padding(.top, 4)
    }
}

// MARK: - Hero

private struct HomeHeroBanner: View {
    let clearedStages: Int
    let totalStages: Int

    private var progress: Double {
        guard totalStages > 0 else { return 0 }
        return min(1, Double(clearedStages) / Double(totalStages))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface,
                            Color.appPrimary.opacity(0.22),
                            Color.appAccent.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.55),
                                    Color.appPrimary.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Decorative shapes (SwiftUI only)
            GeometryReader { geo in
                Circle()
                    .fill(Color.appPrimary.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .offset(x: geo.size.width * 0.55, y: -40)
                Circle()
                    .fill(Color.appAccent.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .offset(x: geo.size.width * 0.7, y: 20)
            }
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 12) {
                Text("Playground")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Stack Skill Points, climb ranks, and chase perfect runs.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Label("\(clearedStages) cleared", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.appBackground.opacity(0.45))
                        )

                    Text("\(Int(progress * 100))% of catalog")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appAccent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appBackground.opacity(0.5))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appPrimary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * progress), height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: Color.appPrimary.opacity(0.22), radius: 24, y: 14)
        .shadow(color: Color.appAccent.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Quick stats

private struct HomeQuickStatsGrid: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.appPrimary)
                Text("Snapshot")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                HomeStatTile(
                    icon: "scope",
                    title: "Skill Points",
                    value: "\(store.totalSkillPoints)",
                    accent: Color.appPrimary
                )
                HomeStatTile(
                    icon: "clock.fill",
                    title: "Play time",
                    value: formatPlayTime(store.totalPlaySeconds),
                    accent: Color.appAccent
                )
                HomeStatTile(
                    icon: "trophy.fill",
                    title: "Achievements",
                    value: "\(store.achievementsUnlocked().count)/\(AchievementID.allCases.count)",
                    accent: Color.appPrimary
                )
                HomeStatTile(
                    icon: "flag.checkered",
                    title: "Runs done",
                    value: "\(store.activitiesFinished)",
                    accent: Color.appAccent
                )
            }
        }
        .padding(16)
        .appCardSoft(cornerRadius: 20)
    }

}

private func formatPlayTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    if hours > 0 { return "\(hours)h \(minutes)m" }
    if minutes > 0 { return "\(minutes)m" }
    return seconds > 0 ? "\(seconds)s" : "—"
}

private struct HomeStatTile: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28, alignment: .leading)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appBackground.opacity(0.5), Color.appSurface.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.appAccent.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Activity card

private struct ActivityHomeCard: View {
    let activity: ActivityKind
    let stars: Int
    let maxStars: Int

    private var progress: Double {
        guard maxStars > 0 else { return 0 }
        return min(1, Double(stars) / Double(maxStars))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.35), Color.appAccent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                Image(systemName: activity.symbolName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(activity.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.appAccent.opacity(0.9))
                }

                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Star progress")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                        Spacer()
                        Text("\(stars)/\(maxStars)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.appAccent)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appBackground.opacity(0.55))
                            Capsule()
                                .fill(Color.appAccent)
                                .frame(width: max(6, geo.size.width * progress))
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .frame(minHeight: 44)
        .appCardElevated(cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel("\(activity.title), \(stars) of \(maxStars) stars")
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(GameProgressStore())
    }
}
