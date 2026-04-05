//
//  GameLevelsView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct GameLevelsView: View {
    let activity: ActivityKind
    @EnvironmentObject private var store: GameProgressStore
    @State private var difficulty: Difficulty = .easy

    var body: some View {
        ScrollScreen {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Difficulty")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(Color.appPrimary)

                    Text("Stages \(difficulty.levelRange().lowerBound)–\(difficulty.levelRange().upperBound)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(16)
                .appCardSoft(cornerRadius: AppStyle.cardRadius)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(Array(difficulty.levelRange()), id: \.self) { level in
                        let id = LevelIdentifier(activity: activity, level: level)
                        let unlocked = store.isUnlocked(id)
                        let stars = store.stars(for: id)

                        if unlocked {
                            NavigationLink {
                                destination(for: level)
                            } label: {
                                LevelCell(level: level, stars: stars, locked: false)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LevelCell(level: level, stars: stars, locked: true)
                        }
                    }
                }
                .padding(.top, 4)

                if allLevelsComplete {
                    Text("You cleared every stage for this activity. Try another difficulty or chase perfect stars.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCardSoft(cornerRadius: 16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var allLevelsComplete: Bool {
        (1...LevelBalance.stagesPerActivity).allSatisfy { store.stars(for: LevelIdentifier(activity: activity, level: $0)) > 0 }
    }

    @ViewBuilder
    private func destination(for level: Int) -> some View {
        switch activity {
        case .shapeShifter:
            ShapeShifterView(level: level)
        case .colorDash:
            ColorDashView(level: level)
        case .sequenceQuest:
            SequenceQuestView(level: level)
        }
    }
}

private struct LevelCell: View {
    let level: Int
    let stars: Int
    let locked: Bool

    @ViewBuilder
    var body: some View {
        let content = VStack(spacing: 8) {
            ZStack {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                } else {
                    Text("\(level)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
            .frame(height: 72)

            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(index < stars ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)

        if locked {
            content.appLockedTile(cornerRadius: 18)
        } else {
            content.appCardElevated(cornerRadius: 18)
        }
    }
}
