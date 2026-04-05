//
//  ActivitiesListView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct ActivitiesListView: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        ScrollScreen {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activities")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Clear stages to stack Skill Points, streak bonuses, and rank progress.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.bottom, 4)

                ForEach(ActivityKind.allCases) { activity in
                    NavigationLink(value: activity) {
                        ActivityRowCardLarge(activity: activity, stars: store.totalStars(for: activity))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: ActivityKind.self) { activity in
            GameLevelsView(activity: activity)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ActivityRowCardLarge: View {
    let activity: ActivityKind
    let stars: Int

    private var starProgress: Double {
        guard LevelBalance.maxStarsPerActivity > 0 else { return 0 }
        return min(1, Double(stars) / Double(LevelBalance.maxStarsPerActivity))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.35), Color.appAccent.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: activity.symbolName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                }
                Spacer()
                Label("\(stars)/\(LevelBalance.maxStarsPerActivity)", systemImage: "star.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            Text(activity.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
            Text(activity.subtitle)
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBackground.opacity(0.55))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appPrimary.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * starProgress))
                }
            }
            .frame(height: 7)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardElevated(cornerRadius: 22)
    }
}
