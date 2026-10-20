//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

@MainActor
final class AIThinkingClock_Tests: XCTestCase {
    private let clock = AIThinkingClock()
    private let asked = Date(timeIntervalSince1970: 1000)

    func test_key_isTheSameForATurn() {
        let first = clock.key(for: "q1")

        XCTAssertEqual(clock.key(for: "q1"), first)
        XCTAssertNotEqual(clock.key(for: "q2"), first)
    }

    func test_update_startsTheThinkingTheFirstTimeTheTurnThinks() {
        let turn = clock.key(for: "q1")

        clock.update(latest: turn, isThinking: false, now: asked)
        XCTAssertNil(clock.start(of: turn), "a turn that never thought has no thinking to time")

        clock.update(latest: turn, isThinking: true, now: asked)
        clock.update(latest: turn, isThinking: true, now: asked.addingTimeInterval(5))
        XCTAssertEqual(clock.start(of: turn), asked)
    }

    func test_update_whenThinkingResumesBeforeTheFirstStep_carriesOn() {
        let turn = thinkingTurn()
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(2))
        clock.update(latest: turn, isThinking: true, now: asked.addingTimeInterval(3))
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(8))

        XCTAssertEqual(clock.start(of: turn), asked)
        XCTAssertEqual(clock.durationOfFirstStep(in: turn, own: nil, now: asked.addingTimeInterval(9)), 8)
    }

    func test_isFirstStep_isTheFirstStepToShowInTheTurn() {
        let turn = thinkingTurn()

        XCTAssertTrue(clock.isFirstStep("r1", of: turn))
        XCTAssertFalse(clock.isFirstStep("r2", of: turn))
        XCTAssertTrue(clock.isFirstStep("r1", of: turn), "so it stays first when its view is made again")
    }

    func test_isFirstStep_whenTheTurnWasNotSeenThinking_isFalse() {
        XCTAssertFalse(clock.isFirstStep("r1", of: clock.key(for: "q1")))
    }

    func test_durationOfFirstStep_whenTheStepArrivedDone_isUntilTheTurnStoppedThinking() {
        let turn = thinkingTurn()
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(8))
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(20))

        XCTAssertEqual(clock.durationOfFirstStep(in: turn, own: nil, now: asked.addingTimeInterval(30)), 8)
    }

    func test_durationOfFirstStep_whenTheStepWasSeenStreaming_isUntilItIsDone() {
        let turn = thinkingTurn()
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(2))
        clock.firstStepIsStreaming(in: turn)

        XCTAssertEqual(clock.durationOfFirstStep(in: turn, own: 4, now: asked.addingTimeInterval(9)), 9)
    }

    func test_durationOfFirstStep_whenItsOwnIsLonger_isItsOwn() {
        let turn = thinkingTurn()
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(3))

        XCTAssertEqual(clock.durationOfFirstStep(in: turn, own: 12, now: asked.addingTimeInterval(3)), 12)
    }

    func test_durationOfFirstStep_isMeasuredOnce() {
        let turn = thinkingTurn()
        clock.firstStepIsStreaming(in: turn)
        _ = clock.durationOfFirstStep(in: turn, own: nil, now: asked.addingTimeInterval(6))

        XCTAssertEqual(
            clock.durationOfFirstStep(in: turn, own: nil, now: asked.addingTimeInterval(60)),
            6,
            "so the step reads the same when its view is made again"
        )
    }

    func test_durationOfFirstStep_whenTheTurnWasNotSeenThinking_isTheStepsOwn() {
        let turn = clock.key(for: "q1")

        XCTAssertEqual(clock.durationOfFirstStep(in: turn, own: 4), 4)
        XCTAssertNil(clock.durationOfFirstStep(in: turn, own: nil))
    }

    func test_showsFirstStep_whenTheStepArrivesDoneAsTheThinkingEnds_opensItAndHoldsTheAnswer() {
        let turn = thinkingTurn()
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(8))
        let arrived = asked.addingTimeInterval(8.1)

        XCTAssertTrue(clock.showsFirstStep(in: turn, now: arrived))
        XCTAssertEqual(
            clock.answerStart(in: turn),
            arrived.addingTimeInterval(StreamingReasoningView.finishedReasoningShown + StreamingReasoningView.foldDuration)
        )
    }

    func test_showsFirstStep_whenTheStepArrivesLater_staysFolded() {
        let turn = thinkingTurn()
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(8))

        XCTAssertFalse(clock.showsFirstStep(in: turn, now: asked.addingTimeInterval(12)))
        XCTAssertNil(clock.answerStart(in: turn))
    }

    func test_showsFirstStep_whenTheStepThoughtInView_staysAsItIs() {
        let turn = thinkingTurn()
        clock.firstStepIsStreaming(in: turn)
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(8))

        XCTAssertFalse(clock.showsFirstStep(in: turn, now: asked.addingTimeInterval(8)), "it showed its reasoning as it came")
    }

    func test_showsFirstStep_whenTheStepIsMadeAgainLater_staysFolded() {
        let turn = thinkingTurn()
        clock.update(latest: turn, isThinking: false, now: asked.addingTimeInterval(8))
        XCTAssertTrue(clock.showsFirstStep(in: turn, now: asked.addingTimeInterval(8)))

        XCTAssertFalse(clock.showsFirstStep(in: turn, now: asked.addingTimeInterval(30)))
    }

    private func thinkingTurn() -> Int {
        let turn = clock.key(for: "q1")
        clock.update(latest: turn, isThinking: true, now: asked)
        return turn
    }
}
