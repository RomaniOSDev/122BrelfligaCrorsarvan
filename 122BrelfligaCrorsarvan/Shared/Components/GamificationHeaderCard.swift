//
//  GamificationHeaderCard.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct GamificationHeaderCard: View {
    let rank: PlayerRank
    let totalPoints: Int
    let winStreak: Int
    let dailyStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.5), Color.appAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, y: 4)
                    Image(systemName: rank.symbolName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your rank")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(rank.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text(rank.detail)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }

            let bar = PlayerRank.progressBar(totalPoints: totalPoints)
            if let next = bar.nextTier {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Next: \(next.title)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                        Spacer()
                        Text("\(totalPoints)/\(next.minSkillPoints)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appBackground.opacity(0.55))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appPrimary.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geo.size.width * bar.fraction))
                        }
                    }
                    .frame(height: 10)
                }
            } else {
                Text("Max rank reached — stay sharp!")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }

            HStack(spacing: 10) {
                streakPill(icon: "flame.fill", title: "Win streak", value: "\(winStreak)")
                streakPill(icon: "calendar", title: "Day streak", value: "\(dailyStreak)")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardElevated(cornerRadius: 22)
    }

    private func streakPill(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.appPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appBackground.opacity(0.55), Color.appSurface.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.appAccent.opacity(0.15), lineWidth: 1)
        )
    }
}
