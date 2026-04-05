//
//  SequenceQuestView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct SequenceQuestView: View {
    @State private var levelState: Int

    init(level: Int) {
        _levelState = State(initialValue: level)
    }

    var body: some View {
        SequenceQuestGameScreen(level: levelState) { newLevel in
            levelState = newLevel
        }
        .id(levelState)
    }
}

private struct SequenceQuestGameScreen: View {
    let onAdvance: (Int) -> Void

    @StateObject private var viewModel: SequenceQuestViewModel
    @EnvironmentObject private var store: GameProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var outcome: GameOutcome?
    @State private var didFinish = false

    init(level: Int, onAdvance: @escaping (Int) -> Void) {
        self.onAdvance = onAdvance
        _viewModel = StateObject(wrappedValue: SequenceQuestViewModel(level: level))
    }

    var body: some View {
        ZStack {
            AppScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    sequencePreview
                    inputPad
                    statusRow
                    PrimaryButton(title: "Restart stage") {
                        didFinish = false
                        viewModel.startRound()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            didFinish = false
            viewModel.startRound()
        }
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
        .onDisappear {
            viewModel.cancelTasks()
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
                    viewModel.startRound()
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
            Text("Watch the pulse order, then rebuild it with quick taps.")
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var sequencePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern stream")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            HStack(spacing: 10) {
                ForEach(Array(viewModel.sequence.enumerated()), id: \.offset) { index, _ in
                    SequenceGlyph(kind: viewModel.sequence[index])
                        .frame(width: 48, height: 48)
                        .opacity(opacity(for: index))
                        .animation(.easeInOut(duration: 0.25), value: viewModel.phase)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .appCardElevated(cornerRadius: AppStyle.cardRadius)
    }

    private func opacity(for index: Int) -> Double {
        if viewModel.isHighlighted(step: index) {
            return 1
        }
        if case .awaitingInput = viewModel.phase {
            return 0.35
        }
        return 0.45
    }

    private var inputPad: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap pad")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 12)], spacing: 12) {
                ForEach(viewModel.availableSymbols, id: \.self) { symbol in
                    Button {
                        viewModel.tap(symbol: symbol)
                    } label: {
                        SequenceGlyph(kind: symbol)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.appPrimary.opacity(0.38),
                                                Color.appAccent.opacity(0.18)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(AppStyle.rimStroke, lineWidth: 1)
                            )
                            .shadow(color: Color.appPrimary.opacity(0.2), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var statusRow: some View {
        HStack {
            Label("Steps \(min(viewModel.inputIndex, viewModel.sequence.count))/\(viewModel.sequence.count)", systemImage: "list.bullet")
                .foregroundStyle(Color.appAccent)
            Spacer()
            Label("Slips \(viewModel.mistakeCount)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.appTextSecondary)
        }
        .font(.subheadline.weight(.semibold))
    }

    private func complete(stars: Int, accuracy: Int) {
        let seconds = max(1, Int(viewModel.elapsed.rounded()))
        let reward = store.recordStageCompletion(
            activity: .sequenceQuest,
            level: viewModel.level,
            starsEarned: stars,
            durationSeconds: seconds
        )
        outcome = GameOutcome(
            activity: .sequenceQuest,
            level: viewModel.level,
            stars: stars,
            seconds: seconds,
            accuracyPercent: accuracy,
            reward: reward
        )
    }

    private func failRun() {
        let seconds = max(1, Int(viewModel.elapsed.rounded()))
        let reward = store.recordStageCompletion(
            activity: .sequenceQuest,
            level: viewModel.level,
            starsEarned: 0,
            durationSeconds: seconds
        )
        let accuracy = max(0, 100 - viewModel.mistakeCount * 20)
        outcome = GameOutcome(
            activity: .sequenceQuest,
            level: viewModel.level,
            stars: 0,
            seconds: seconds,
            accuracyPercent: accuracy,
            reward: reward
        )
    }
}

struct SequenceGlyph: View {
    let kind: Int

    var body: some View {
        ZStack {
            switch kind % 4 {
            case 0:
                Circle().fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 6, y: 3)
            case 1:
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.appAccent.opacity(0.35), radius: 6, y: 3)
            case 2:
                DiamondShape().fill(
                    LinearGradient(
                        colors: [Color.appTextPrimary, Color.appTextSecondary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            default:
                TriangleMiniShape().fill(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.95), Color.appAccent.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.3), radius: 5, y: 2)
            }
        }
        .padding(10)
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct TriangleMiniShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
