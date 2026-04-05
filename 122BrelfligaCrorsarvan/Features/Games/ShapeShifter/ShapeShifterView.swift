//
//  ShapeShifterView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct ShapeShifterView: View {
    @State private var levelState: Int

    init(level: Int) {
        _levelState = State(initialValue: level)
    }

    var body: some View {
        ShapeShifterGameScreen(level: levelState) { newLevel in
            levelState = newLevel
        }
        .id(levelState)
    }
}

private struct ShapeShifterGameScreen: View {
    let onAdvance: (Int) -> Void

    @StateObject private var viewModel: ShapeShifterViewModel
    @EnvironmentObject private var store: GameProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var outcome: GameOutcome?
    @State private var didFinish = false

    init(level: Int, onAdvance: @escaping (Int) -> Void) {
        self.onAdvance = onAdvance
        _viewModel = StateObject(wrappedValue: ShapeShifterViewModel(level: level))
    }

    var body: some View {
        ZStack {
            AppScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    playfield
                    controls
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            didFinish = false
            viewModel.startClock()
        }
        .onChange(of: viewModel.phase) { newPhase in
            if case let .completed(stars, accuracy) = newPhase, !didFinish {
                didFinish = true
                finishRun(stars: stars, accuracy: accuracy)
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
                    viewModel.resetLevel()
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
            Text("Drag every shape onto its faint outline.")
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
            HStack {
                Label(String(format: "%.1fs", viewModel.elapsed), systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                Spacer()
                Text("Snap within \(Int(viewModel.ruleSet.tolerance)) pt")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private var playfield: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppStyle.surfaceFill)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppStyle.rimStroke.opacity(0.9), lineWidth: 1)
                ForEach(viewModel.pieces) { piece in
                    targetOutline(for: piece, in: size)
                }
                ForEach(viewModel.pieces) { piece in
                    draggableShape(for: piece, in: size)
                }
            }
            .onAppear {
                viewModel.updateFieldSize(size)
            }
            .onChange(of: size.width) { _ in
                viewModel.updateFieldSize(size)
            }
            .onChange(of: size.height) { _ in
                viewModel.updateFieldSize(size)
            }
        }
        .frame(height: 420)
        .shadow(color: Color.appPrimary.opacity(0.22), radius: 24, y: 14)
        .shadow(color: Color.appAccent.opacity(0.12), radius: 10, y: 5)
    }

    private func targetOutline(for piece: ShapePiece, in size: CGSize) -> some View {
        let point = CGPoint(x: piece.target.x * size.width, y: piece.target.y * size.height)
        return Group {
            switch piece.variant % 3 {
            case 0:
                Circle()
                    .stroke(Color.appAccent.opacity(0.55), lineWidth: 2)
            case 1:
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.appAccent.opacity(0.55), lineWidth: 2)
            default:
                TriangleShape()
                    .stroke(Color.appAccent.opacity(0.55), lineWidth: 2)
            }
        }
        .frame(width: 54, height: 54)
        .position(point)
    }

    private func draggableShape(for piece: ShapePiece, in size: CGSize) -> some View {
        let point = CGPoint(x: piece.normalized.x * size.width, y: piece.normalized.y * size.height)
        return Group {
            switch piece.variant % 3 {
            case 0:
                Circle().fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            case 1:
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            default:
                TriangleShape().fill(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.95), Color.appAccent.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(width: 48, height: 48)
        .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, y: 4)
        .position(point)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    viewModel.updateDrag(id: piece.id, translation: value.translation)
                }
                .onEnded { _ in
                    viewModel.endDrag(id: piece.id)
                }
        )
    }

    private var controls: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Restart stage") {
                didFinish = false
                viewModel.resetLevel()
            }
        }
    }

    private func finishRun(stars: Int, accuracy: Int) {
        let seconds = max(1, Int(viewModel.elapsed.rounded()))
        let reward = store.recordStageCompletion(
            activity: .shapeShifter,
            level: viewModel.level,
            starsEarned: stars,
            durationSeconds: seconds
        )
        outcome = GameOutcome(
            activity: .shapeShifter,
            level: viewModel.level,
            stars: stars,
            seconds: seconds,
            accuracyPercent: accuracy,
            reward: reward
        )
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
