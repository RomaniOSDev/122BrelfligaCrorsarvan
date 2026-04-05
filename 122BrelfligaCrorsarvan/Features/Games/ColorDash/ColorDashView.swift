//
//  ColorDashView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct ColorDashView: View {
    @State private var levelState: Int

    init(level: Int) {
        _levelState = State(initialValue: level)
    }

    var body: some View {
        ColorDashGameScreen(level: levelState) { newLevel in
            levelState = newLevel
        }
        .id(levelState)
    }
}

private struct ColorDashGameScreen: View {
    let onAdvance: (Int) -> Void

    @StateObject private var viewModel: ColorDashViewModel
    @EnvironmentObject private var store: GameProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var outcome: GameOutcome?
    @State private var didFinish = false

    init(level: Int, onAdvance: @escaping (Int) -> Void) {
        self.onAdvance = onAdvance
        _viewModel = StateObject(wrappedValue: ColorDashViewModel(level: level))
    }

    var body: some View {
        ZStack {
            AppScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    targetPanel
                    optionsGrid
                    statsRow
                    PrimaryButton(title: "Restart stage") {
                        didFinish = false
                        viewModel.startSession()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.phase) { phase in
            switch phase {
            case let .completed(stars, accuracy):
                if !didFinish {
                    didFinish = true
                    complete(stars: stars, accuracy: accuracy)
                }
            case .failed:
                if !didFinish {
                    didFinish = true
                    failRun()
                }
            default:
                break
            }
        }
        .fullScreenCover(item: $outcome) { value in
            GameResultView(
                outcome: value,
                onLevels: {
                    outcome = nil
                    dismiss()
                },
                onRetry: {
                    outcome = nil
                    didFinish = false
                    viewModel.startSession()
                },
                onNext: {
                    outcome = nil
                    didFinish = false
                    if value.stars > 0, value.level < LevelBalance.stagesPerActivity {
                        onAdvance(value.level + 1)
                    }
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stage \(viewModel.level)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
            Text("Tap the swatch that matches the glowing target.")
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var targetPanel: some View {
        VStack(spacing: 12) {
            Text("Target")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppStyle.surfaceFill)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(AppStyle.rimStroke, lineWidth: 1)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                viewModel.color(for: viewModel.targetIndex),
                                viewModel.color(for: viewModel.targetIndex).opacity(0.75)
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 52
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.appAccent.opacity(0.55), radius: 18, y: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            ProgressView(value: viewModel.timeLeft, total: max(0.1, viewModel.roundLimit))
                .tint(Color.appAccent)
        }
        .padding(14)
        .appCardElevated(cornerRadius: 22)
        .rotationEffect(.degrees(viewModel.rotation))
        .animation(.easeInOut(duration: 0.2), value: viewModel.rotation)
    }

    private var optionsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
            ForEach(viewModel.optionIndices, id: \.self) { index in
                Button {
                    viewModel.tap(option: index)
                } label: {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    viewModel.color(for: index),
                                    viewModel.color(for: index).opacity(0.82)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(minHeight: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.appTextPrimary.opacity(0.35),
                                            Color.appAccent.opacity(0.25)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: viewModel.color(for: index).opacity(0.45), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
        }
    }

    private var statsRow: some View {
        HStack {
            Label("\(viewModel.correctCount)/\(viewModel.matchGoal)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Color.appAccent)
            Spacer()
            Label("Misses \(viewModel.wrongCount)", systemImage: "xmark.circle.fill")
                .foregroundStyle(Color.appTextSecondary)
        }
        .font(.subheadline.weight(.semibold))
    }

    private func complete(stars: Int, accuracy: Int) {
        let seconds = max(1, Int(viewModel.elapsed.rounded()))
        let reward = store.recordStageCompletion(
            activity: .colorDash,
            level: viewModel.level,
            starsEarned: stars,
            durationSeconds: seconds
        )
        outcome = GameOutcome(
            activity: .colorDash,
            level: viewModel.level,
            stars: stars,
            seconds: seconds,
            accuracyPercent: accuracy,
            reward: reward
        )
    }

    private func failRun() {
        let seconds = max(1, Int(viewModel.elapsed.rounded()))
        let total = viewModel.correctCount + viewModel.wrongCount
        let accuracy = total > 0 ? Int((Double(viewModel.correctCount) / Double(total)) * 100) : 0
        let reward = store.recordStageCompletion(
            activity: .colorDash,
            level: viewModel.level,
            starsEarned: 0,
            durationSeconds: seconds
        )
        outcome = GameOutcome(
            activity: .colorDash,
            level: viewModel.level,
            stars: 0,
            seconds: seconds,
            accuracyPercent: accuracy,
            reward: reward
        )
    }
}
