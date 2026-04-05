//
//  ProfileView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var confirmReset = false

    var body: some View {
        ScrollScreen {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profile")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Track ranks, streaks, Skill Points, and milestones.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)

                statsSection

                achievementsSection

                PrimaryButton(title: "Reset All Progress") {
                    confirmReset = true
                }

                Text("This clears stars, unlocks, timers, Skill Points, streaks, and run counts. Onboarding stays complete.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                }
                .accessibilityLabel("Settings")
            }
        }
        .alert("Reset everything?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetAllProgress()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            statRow(title: "Rank", value: store.currentRank.title)
            statRow(title: "Skill Points", value: "\(store.totalSkillPoints)")
            statRow(title: "Win streak", value: "\(store.consecutiveWins)")
            statRow(title: "Day streak", value: "\(store.dailyStreak)")
            statRow(title: "Stages cleared", value: "\(store.clearedStagesCount)")
            statRow(title: "Runs finished", value: "\(store.activitiesFinished)")
            statRow(title: "Total play time", value: formattedTime(store.totalPlaySeconds))
            statRow(title: "Achievements unlocked", value: "\(store.achievementsUnlocked().count)/\(AchievementID.allCases.count)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardElevated(cornerRadius: AppStyle.cardRadius)
    }

    private func statRow(title: String, value: String) -> some View {
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

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            if store.achievementsUnlocked().isEmpty {
                Text("Play a stage to start collecting milestones.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                ForEach(store.achievementsUnlocked()) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(.vertical, 6)
                }
            }

            Divider().background(Color.appTextSecondary.opacity(0.3))

            Text("Locked")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)

            let unlockedSet = Set(store.achievementsUnlocked())
            let locked = AchievementID.allCases.filter { !unlockedSet.contains($0) }

            if locked.isEmpty {
                Text("Everything is unlocked. Amazing focus.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                ForEach(locked) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.appTextSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary.opacity(0.7))
                            Text(item.detail)
                                .font(.caption2)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardElevated(cornerRadius: AppStyle.cardRadius)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        }
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, secs)
        }
        return String(format: "%ds", secs)
    }
}
