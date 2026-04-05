//
//  SequenceQuestViewModel.swift
//  122BrelfligaCrorsarvan
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class SequenceQuestViewModel: ObservableObject {
    enum Phase: Equatable {
        case preparing
        case showingStep(Int)
        case awaitingInput
        case completed(stars: Int, accuracy: Int)
        case failed
    }

    @Published private(set) var sequence: [Int] = []
    @Published private(set) var inputIndex: Int = 0
    @Published private(set) var phase: Phase = .preparing
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var mistakeCount: Int = 0

    let level: Int
    let sequenceLength: Int
    let revealInterval: TimeInterval
    let mistakeAllowance: Int
    let distractorSymbols: [Int]

    private var revealTask: Task<Void, Never>?
    private var clock: AnyCancellable?

    init(level: Int) {
        self.level = level
        let difficulty = Difficulty.difficulty(forLevel: level)
        let length = min(7, 3 + (level + 1) / 2)
        self.sequenceLength = length
        switch difficulty {
        case .easy:
            revealInterval = 0.75
            mistakeAllowance = 2
        case .normal:
            revealInterval = 0.55
            mistakeAllowance = 1
        case .hard:
            revealInterval = 0.4
            mistakeAllowance = 0
        }
        if difficulty == .hard {
            var extras = Set<Int>()
            while extras.count < 3 {
                extras.insert(Int.random(in: 0..<4))
            }
            distractorSymbols = Array(extras)
        } else {
            distractorSymbols = []
        }
        buildSequence()
    }

    func startRound() {
        cancelTasks()
        phase = .preparing
        inputIndex = 0
        mistakeCount = 0
        buildSequence()
        let origin = Date()
        clock = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed = Date().timeIntervalSince(origin)
            }
        revealTask = Task { await playSequence() }
    }

    func cancelTasks() {
        revealTask?.cancel()
        revealTask = nil
        clock?.cancel()
        clock = nil
    }

    private func buildSequence() {
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<4) }
    }

    private func playSequence() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        for step in 0..<sequence.count {
            if Task.isCancelled { return }
            await MainActor.run {
                self.phase = .showingStep(step)
            }
            try? await Task.sleep(nanoseconds: UInt64(revealInterval * 1_000_000_000))
        }
        await MainActor.run {
            self.phase = .awaitingInput
            self.inputIndex = 0
        }
    }

    func tap(symbol: Int) {
        guard case .awaitingInput = phase else { return }
        guard inputIndex < sequence.count else { return }
        let expected = sequence[inputIndex]
        if symbol == expected {
            inputIndex += 1
            if inputIndex >= sequence.count {
                finishSuccess()
            }
        } else {
            mistakeCount += 1
            if mistakeCount > mistakeAllowance {
                cancelTasks()
                phase = .failed
            }
        }
    }

    private func finishSuccess() {
        cancelTasks()
        let accuracy = max(0, 100 - mistakeCount * 15)
        let stars = starsFrom(accuracy: accuracy, time: elapsed)
        phase = .completed(stars: stars, accuracy: accuracy)
    }

    private func starsFrom(accuracy: Int, time: TimeInterval) -> Int {
        let cap: TimeInterval
        switch Difficulty.difficulty(forLevel: level) {
        case .easy: cap = 90
        case .normal: cap = 70
        case .hard: cap = 55
        }
        if mistakeCount == 0 && time <= cap { return 3 }
        if accuracy >= 85 { return 2 }
        return 1
    }

    var availableSymbols: [Int] {
        let base = Array(0..<4)
        if distractorSymbols.isEmpty {
            return base
        }
        return Array(Set(base + distractorSymbols)).sorted()
    }

    func isHighlighted(step: Int) -> Bool {
        if case let .showingStep(index) = phase {
            return index == step
        }
        return false
    }
}
