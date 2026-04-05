//
//  ShapeShifterViewModel.swift
//  122BrelfligaCrorsarvan
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ShapeShifterViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case completed(stars: Int, accuracy: Int)
    }

    @Published private(set) var pieces: [ShapePiece] = []
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var phase: Phase = .playing

    let level: Int
    private var timerCancellable: AnyCancellable?
    private var fieldSize: CGSize = .init(width: 320, height: 420)
    private var dragOrigins: [UUID: CGPoint] = [:]

    var ruleSet: ShapeShifterRules {
        ShapeShifterRules.rules(for: level)
    }

    init(level: Int) {
        self.level = level
        rebuildPieces()
    }

    func updateFieldSize(_ size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        fieldSize = size
    }

    func startClock() {
        guard timerCancellable == nil else { return }
        elapsed = 0
        let origin = Date()
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed = Date().timeIntervalSince(origin)
            }
    }

    func stopClock() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func updateDrag(id: UUID, translation: CGSize) {
        guard case .playing = phase else { return }
        guard let index = pieces.firstIndex(where: { $0.id == id }) else { return }
        if dragOrigins[id] == nil {
            dragOrigins[id] = pieces[index].normalized
        }
        guard let origin = dragOrigins[id] else { return }
        let nx = origin.x + translation.width / fieldSize.width
        let ny = origin.y + translation.height / fieldSize.height
        pieces[index].normalized = CGPoint(
            x: min(1, max(0, nx)),
            y: min(1, max(0, ny))
        )
        evaluateWin()
    }

    func endDrag(id: UUID) {
        dragOrigins[id] = nil
    }

    func resetLevel() {
        stopClock()
        phase = .playing
        dragOrigins.removeAll()
        rebuildPieces()
        startClock()
    }

    private func rebuildPieces() {
        let rules = ruleSet
        let targets = ShapeShifterRules.scatterTargets(count: rules.count)
        let starts = ShapeShifterRules.scatterStarts(count: rules.count, avoiding: targets)
        pieces = zip(targets, starts).enumerated().map { index, pair in
            let (target, start) = pair
            return ShapePiece(
                id: UUID(),
                normalized: start,
                target: target,
                variant: index % 3
            )
        }
    }

    private func evaluateWin() {
        let tol = ruleSet.tolerance
        let ok = pieces.allSatisfy { piece in
            let dx = (piece.normalized.x - piece.target.x) * fieldSize.width
            let dy = (piece.normalized.y - piece.target.y) * fieldSize.height
            return hypot(dx, dy) <= tol
        }
        guard ok else { return }
        stopClock()
        let stars = starsForTime(elapsed)
        let accuracy = max(0, min(100, Int(100 - elapsed * 3)))
        phase = .completed(stars: stars, accuracy: accuracy)
    }

    private func starsForTime(_ time: TimeInterval) -> Int {
        let r = ruleSet
        if time <= r.threeStarSeconds { return 3 }
        if time <= r.twoStarSeconds { return 2 }
        return 1
    }
}

struct ShapePiece: Identifiable {
    let id: UUID
    var normalized: CGPoint
    let target: CGPoint
    let variant: Int
}

struct ShapeShifterRules {
    let count: Int
    let tolerance: CGFloat
    let threeStarSeconds: Double
    let twoStarSeconds: Double

    static func rules(for level: Int) -> ShapeShifterRules {
        let tier = Difficulty.difficulty(forLevel: level)
        let base: Int
        switch tier {
        case .easy: base = 2
        case .normal: base = 3
        case .hard: base = 4
        }
        let count = min(6, base + level / 3)
        let tol = max(22, 40 - CGFloat(level) * 1.15)
        let three: Double
        let two: Double
        switch tier {
        case .easy:
            three = 18
            two = 28
        case .normal:
            three = 14
            two = 22
        case .hard:
            three = 10
            two = 16
        }
        return ShapeShifterRules(count: max(2, count), tolerance: tol, threeStarSeconds: three, twoStarSeconds: two)
    }

    static func scatterTargets(count: Int) -> [CGPoint] {
        let center = CGPoint(x: 0.5, y: 0.38)
        let radius: CGFloat = 0.22
        return (0..<count).map { index in
            let angle = (CGFloat(index) / CGFloat(max(1, count))) * .pi * 2 * 0.85 + 0.2
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius * 0.75
            )
        }
    }

    static func scatterStarts(count: Int, avoiding targets: [CGPoint]) -> [CGPoint] {
        var results: [CGPoint] = []
        for index in 0..<count {
            let y = 0.62 + CGFloat(index % 3) * 0.06
            let x = 0.18 + CGFloat(index) * 0.14
            var point = CGPoint(x: min(0.85, x), y: min(0.9, y))
            for target in targets {
                if hypot((point.x - target.x) * 320, (point.y - target.y) * 400) < 60 {
                    point.x += 0.1
                }
            }
            results.append(point)
        }
        return results
    }
}
