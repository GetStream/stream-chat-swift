//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Times the thinking of each turn a list sees start, so the thinking shown before anything of
// a reply arrives and the reasoning step that takes its place read as one: "Thinking… 8s",
// then "Thought for 8s". A model that sends its reasoning only with its answer sends a step
// with no time of its own.
@MainActor
final class AIThinkingClock {
    private struct Turn {
        var start: Date
        var end: Date?
        var firstStep: String?
        var firstStepStreamed = false
        var firstStepDuration: TimeInterval?
        // When a first step that arrived done opened to show its reasoning.
        var firstStepShown: Date?
    }

    // How soon after a turn stops thinking its first step has to arrive, done, to open and show
    // its reasoning: it came with the reply that ended the thinking.
    private static let arrivalWindow: TimeInterval = 1

    private var keys: [AnyHashable: Int] = [:]
    private var turns: [Int: Turn] = [:]

    nonisolated init() { /* Nothing to set up. */ }

    func key(for turn: AnyHashable) -> Int {
        if let key = keys[turn] { return key }
        let key = keys.count
        keys[turn] = key
        return key
    }

    // A turn's thinking starts the first time it is the latest turn and thinking, and ends when
    // it stops. Thinking that resumes before the first step shows carries on, rather than
    // ending at the pause.
    func update(latest turn: Int?, isThinking: Bool, now: Date = Date()) {
        guard let turn else { return }
        if isThinking {
            if turns[turn] == nil {
                turns[turn] = Turn(start: now)
            } else if turns[turn]?.firstStep == nil {
                turns[turn]?.end = nil
            }
        } else if turns[turn] != nil, turns[turn]?.end == nil {
            turns[turn]?.end = now
        }
    }

    func start(of turn: Int) -> Date? {
        turns[turn]?.start
    }

    // Whether `step` takes over from a turn's thinking: the first reasoning step to show in a
    // turn that was seen thinking.
    func isFirstStep(_ step: String, of turn: Int) -> Bool {
        guard turns[turn] != nil else { return false }
        if turns[turn]?.firstStep == nil {
            turns[turn]?.firstStep = step
        }
        return turns[turn]?.firstStep == step
    }

    func firstStepIsStreaming(in turn: Int) {
        turns[turn]?.firstStepStreamed = true
    }

    // How long a turn's first step thought: from when the turn started thinking until the step
    // was done. That is now for a step seen streaming, and when the turn stopped thinking for
    // one that arrived done. The step's own time counts when it is longer.
    func durationOfFirstStep(in turn: Int, own: TimeInterval?, now: Date = Date()) -> TimeInterval? {
        guard let timed = turns[turn] else { return own }
        if let measured = timed.firstStepDuration { return measured }
        let done = timed.firstStepStreamed ? now : (timed.end ?? now)
        let measured = max(own ?? 0, done.timeIntervalSince(timed.start))
        turns[turn]?.firstStepDuration = measured
        return measured
    }

    // Whether a turn's first step, which arrived done with the reply that ended the thinking,
    // opens to show its reasoning before it folds and the answer starts. It does as it arrives:
    // a step that thought in view showed its reasoning as it came, and one made again later
    // stays folded.
    func showsFirstStep(in turn: Int, now: Date = Date()) -> Bool {
        guard let timed = turns[turn], !timed.firstStepStreamed else { return false }
        if let shown = timed.firstStepShown {
            return now.timeIntervalSince(shown) < Self.arrivalWindow
        }
        guard let end = timed.end, now.timeIntervalSince(end) < Self.arrivalWindow else { return false }
        turns[turn]?.firstStepShown = now
        return true
    }

    // When a turn's answer starts: once a first step that showed its reasoning has folded.
    func answerStart(in turn: Int) -> Date? {
        turns[turn]?.firstStepShown?.addingTimeInterval(
            StreamingReasoningView.finishedReasoningShown + StreamingReasoningView.foldDuration
        )
    }
}

// The turn of a list a view is in, whose clock times its thinking.
struct AIThinkingTurn {
    let clock: AIThinkingClock
    let key: Int
}

private struct AIThinkingTurnKey: EnvironmentKey {
    static let defaultValue: AIThinkingTurn? = nil
}

extension EnvironmentValues {
    var aiThinkingTurn: AIThinkingTurn? {
        get { self[AIThinkingTurnKey.self] }
        set { self[AIThinkingTurnKey.self] = newValue }
    }
}
