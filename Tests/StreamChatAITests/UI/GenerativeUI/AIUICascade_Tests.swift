//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

@MainActor
final class AIUICascade_Tests: XCTestCase {
    private let cascade = AIUICascade()

    func testAPartThatComesInAloneDoesNotWait() {
        XCTAssertEqual(cascade.delay(at: 100), 0)
        XCTAssertEqual(cascade.delay(at: 101), 0, "the part before it is long in")
    }

    func testPartsThatComeInAtOnceFollowOneAnother() {
        let delays = (0..<3).map { _ in cascade.delay(at: 100) }

        XCTAssertEqual(delays[0], 0)
        XCTAssertEqual(delays[1], AIUICascade.step, accuracy: 0.0001)
        XCTAssertEqual(delays[2], 2 * AIUICascade.step, accuracy: 0.0001)
    }

    func testAPartWaitsOnlyForThePartsStillToComeIn() {
        _ = cascade.delay(at: 100)
        _ = cascade.delay(at: 100)

        XCTAssertEqual(cascade.delay(at: 100 + AIUICascade.step), AIUICascade.step, accuracy: 0.0001)
    }

    func testNoPartWaitsLong() {
        let delays = (0..<20).map { _ in cascade.delay(at: 100) }

        XCTAssertEqual(delays.max() ?? 0, AIUICascade.longestWait, accuracy: 0.0001)
    }

    func testAPartComesInWithThePartAroundItWhileThatShowsForTheFirstTime() {
        let stage = AIUIStage(isCarried: false, cascade: cascade)

        XCTAssertTrue(stage.carrying(true).isCarried)
        XCTAssertFalse(stage.carrying(false).isCarried, "a part that has shown lets what it holds come in later")
        XCTAssertTrue(AIUIStage(isCarried: true, cascade: cascade).carrying(false).isCarried, "what a carried part holds is carried too")
    }
}
