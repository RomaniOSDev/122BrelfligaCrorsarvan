//
//  ColorDashViewModel.swift
//  122BrelfligaCrorsarvan
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ColorDashViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case completed(stars: Int, accuracy: Int)
        case failed
    }

    @Published private(set) var targetIndex: Int = 0
    @Published private(set) var optionIndices: [Int] = []
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var wrongCount: Int = 0
    @Published private(set) var timeLeft: TimeInterval = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var rotation: Double = 0
    @Published private(set) var phase: Phase = .playing

    let level: Int
    let matchGoal: Int
    let roundLimit: TimeInterval

    private let difficulty: Difficulty
    private let maxWrong: Int
    private let paletteCount = 6

    private var tick: AnyCancellable?
    private var clock: AnyCancellable?
    private var roundStart: Date = .init()

    init(level: Int) {
        self.level = level
        self.difficulty = Difficulty.difficulty(forLevel: level)
        self.matchGoal = 8 + level
        switch self.difficulty {
        case .easy:
            roundLimit = 2.0
            maxWrong = 6
        case .normal:
            roundLimit = 1.35
            maxWrong = 4
        case .hard:
            roundLimit = 0.85
            maxWrong = 3
        }
        startSession()
    }

    func startSession() {
        stopTimers()
        phase = .playing
        correctCount = 0
        wrongCount = 0
        elapsed = 0
        rotation = 0
        roundStart = Date()
        let origin = Date()
        clock = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed = Date().timeIntervalSince(origin)
            }
        scheduleRound()
    }

    func stopTimers() {
        tick?.cancel()
        tick = nil
        clock?.cancel()
        clock = nil
    }

    private func scheduleRound() {
        guard case .playing = phase else { return }
        tick?.cancel()
        targetIndex = Int.random(in: 0..<paletteCount)
        var options = Set<Int>()
        options.insert(targetIndex)
        let extra = difficulty == .hard ? 5 : 4
        while options.count < min(paletteCount, extra) {
            options.insert(Int.random(in: 0..<paletteCount))
        }
        optionIndices = Array(options).shuffled()
        timeLeft = roundLimit
        roundStart = Date()

        tick = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickRound()
            }
    }

    private func tickRound() {
        guard case .playing = phase else { return }
        if difficulty == .hard {
            rotation += 1.1
        }
        let remaining = roundLimit - Date().timeIntervalSince(roundStart)
        timeLeft = max(0, remaining)
        if remaining <= 0 {
            handleWrong()
        }
    }

    private func handleWrong() {
        tick?.cancel()
        wrongCount += 1
        if wrongCount >= maxWrong {
            stopTimers()
            phase = .failed
            return
        }
        scheduleRound()
    }

    func tap(option: Int) {
        guard case .playing = phase else { return }
        tick?.cancel()
        if option == targetIndex {
            correctCount += 1
            if correctCount >= matchGoal {
                finishSuccess()
            } else {
                scheduleRound()
            }
        } else {
            handleWrong()
        }
    }

    private func finishSuccess() {
        stopTimers()
        let attempts = correctCount + wrongCount
        let accuracy = attempts > 0 ? Int((Double(correctCount) / Double(attempts)) * 100) : 100
        let stars = starsFrom(accuracy: accuracy, time: elapsed)
        phase = .completed(stars: stars, accuracy: accuracy)
    }

    private func starsFrom(accuracy: Int, time: TimeInterval) -> Int {
        let timeCap: TimeInterval
        switch difficulty {
        case .easy: timeCap = 120
        case .normal: timeCap = 90
        case .hard: timeCap = 70
        }
        if accuracy >= 92 && time <= timeCap { return 3 }
        if accuracy >= 78 { return 2 }
        return 1
    }

    func color(for index: Int) -> Color {
        switch index % 6 {
        case 0: return .red
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        default: return .cyan
        }
    }
}
