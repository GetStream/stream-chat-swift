//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class RecordButton_Tests: XCTestCase {
    private var subject: RecordButton! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        subject.setUp()
        subject.setUpAppearance()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - setUp

    func test_setUp_wasConfiguredCorrectly() {
        XCTAssertEqual(
            subject.actions(
                forTarget: subject,
                forControlEvent: .touchDown
            )?.first,
            "didTouchDown:"
        )
        XCTAssertEqual(
            subject.actions(
                forTarget: subject,
                forControlEvent: .touchUpInside
            )?.first,
            "didTouchUp:"
        )
    }

    // MARK: - setUpAppearance

    func test_setUpAppearance_wasConfiguredCorrectly() {
        XCTAssertEqual(
            subject.image(for: .normal)?.pngData(),
            subject.appearance.images.mic.tinted(with: subject.appearance.colorPalette.textLowEmphasis)?.pngData()
        )

        XCTAssertEqual(
            subject.image(for: .highlighted)?.pngData(),
            subject.appearance.images.mic.tinted(with: subject.appearance.colorPalette.accentPrimary)?.pngData()
        )
    }

    // MARK: - didTouchDown

    func test_touchDown_touchDownHandlerWasCalled() {
        let handlerCallExpectation = expectation(description: "Handler was called")
        subject.touchDownHandler = { handlerCallExpectation.fulfill() }

        subject.didTouchDown(subject)

        wait(for: [handlerCallExpectation], timeout: defaultTimeout)
    }

    func test_touchDown_touchDownHandlerAndCompletedHandlerWereCalledOnce() {
        let handlerCallExpectation = expectation(description: "Handler was called")
        var touchDownHandlerTimesCalled = 0
        var completedHandlerTimesCalled = 0
        subject.touchDownHandler = { touchDownHandlerTimesCalled += 1 }
        subject.completedHandler = {
            handlerCallExpectation.fulfill()
            completedHandlerTimesCalled += 1
        }

        subject.didTouchDown(subject)

        wait(for: [handlerCallExpectation], timeout: defaultTimeout)
        XCTAssertEqual(touchDownHandlerTimesCalled, 1)
        XCTAssertEqual(completedHandlerTimesCalled, 1)
    }

    func test_touchDown_multipleTimesCalled_touchDownHandlerWasCalledMultipleTimesCompletedHandlerWasCalledOnce() {
        let expectedTouchDownHandlerTimes = 5
        let expectedCompletedHandlerTimes = 1
        let handlerCallExpectation = expectation(description: "Handler was called")
        var touchDownHandlerTimesCalled = 0
        var completedHandlerTimesCalled = 0
        subject.touchDownHandler = { touchDownHandlerTimesCalled += 1 }
        subject.completedHandler = {
            handlerCallExpectation.fulfill()
            completedHandlerTimesCalled += 1
        }

        (0..<expectedTouchDownHandlerTimes).forEach { _ in subject.didTouchDown(subject) }

        wait(for: [handlerCallExpectation], timeout: defaultTimeout)
        XCTAssertEqual(touchDownHandlerTimesCalled, expectedTouchDownHandlerTimes)
        XCTAssertEqual(completedHandlerTimesCalled, expectedCompletedHandlerTimes)
    }

    func test_touchDown_isHighlightedWasSetToTrue() {
        subject.didTouchDown(subject)

        XCTAssertTrue(subject.isHighlighted)
    }

    // MARK: - didTouchUp

    func test_didTouchUp_whileItHasAScheduledEvent_incompleteHandlerWasCalled() {
        let handlerCallExpectation = expectation(description: "Handler was called")
        subject.incompleteHandler = { handlerCallExpectation.fulfill() }

        subject.didTouchDown(subject)
        subject.didTouchUp(subject)

        wait(for: [handlerCallExpectation], timeout: defaultTimeout)
    }

    func test_didTouchUp_whileItHasAScheduledEvent_completedHandlerWasNotCalled() {
        let handlerCallExpectation = expectation(description: "Handler was called")
        handlerCallExpectation.isInverted = true
        subject.completedHandler = { handlerCallExpectation.fulfill() }

        subject.didTouchDown(subject)
        subject.didTouchUp(subject)

        wait(for: [handlerCallExpectation], timeout: defaultTimeout)
    }

    func test_didTouchUp_withoutAScheduledEvent_incompleteHandlerWasNotCalled() {
        let completedHandlerCallExpectation = expectation(description: "Completed handler was called")
        let incompleteHandlerCallExpectation = expectation(description: "Incomplete handler was called")
        incompleteHandlerCallExpectation.isInverted = true
        subject.completedHandler = { completedHandlerCallExpectation.fulfill() }
        subject.incompleteHandler = { incompleteHandlerCallExpectation.fulfill() }

        subject.didTouchDown(subject)
        wait(for: [completedHandlerCallExpectation], timeout: defaultTimeout)

        subject.didTouchUp(subject)
        wait(for: [incompleteHandlerCallExpectation], timeout: defaultTimeout)
    }

    func test_didTouchUp_isHighlightedWasSetToFalse() {
        subject.didTouchDown(subject)
        XCTAssertTrue(subject.isHighlighted)

        subject.didTouchUp(subject)

        XCTAssertFalse(subject.isHighlighted)
    }

    // MARK: - Snapshots

    func test_appearance_wasConfiguredCorrectly() {
        AssertSnapshot(subject)
    }
}
