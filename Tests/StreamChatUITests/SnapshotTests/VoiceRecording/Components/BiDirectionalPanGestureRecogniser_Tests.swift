//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
import StreamChatUI
import XCTest

final class BiDirectionalPanGestureRecogniser_Tests: XCTestCase {
    final class StubContainerBiDirectionalPanGestureRecogniser: BidirectionalPanGestureRecogniser {
        var velocityInViewResult: CGPoint = .zero
        override func velocity(in view: UIView?) -> CGPoint { velocityInViewResult }
    }

    private var subject: StubContainerBiDirectionalPanGestureRecogniser! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - touchesBegan

    func test_touchesBegan_callsExpectedHandler() {
        let expectation = expectation(description: "Touches began handler called")
        subject.touchesBeganHandler = { expectation.fulfill() }

        subject.touchesBegan(Set(), with: UIEvent())

        wait(for: [expectation], timeout: defaultTimeout)
    }

    // MARK: - touchesMoved

    func test_touchesMoved_movementWasHorizontal_callsExpectedHandler() {
        let expectationHorizontal = expectation(description: "Horizontal movement handler called")
        let expectationVertical = expectation(description: "Vertical movement handler called")
        expectationVertical.isInverted = true
        subject.horizontalMovementHandler = { _ in expectationHorizontal.fulfill() }
        subject.verticalMovementHandler = { _ in expectationVertical.fulfill() }
        subject.velocityInViewResult = .init(x: 100, y: 0)

        subject.touchesBegan(Set(), with: UIEvent())
        subject.touchesMoved([UITouch()], with: UIEvent())

        wait(for: [expectationHorizontal, expectationVertical], timeout: defaultTimeout)
    }

    func test_touchesMoved_movementWasVertical_callsExpectedHandler() {
        let expectationHorizontal = expectation(description: "Horizontal movement handler called")
        expectationHorizontal.isInverted = true
        let expectationVertical = expectation(description: "Vertical movement handler called")
        subject.horizontalMovementHandler = { _ in expectationHorizontal.fulfill() }
        subject.verticalMovementHandler = { _ in expectationVertical.fulfill() }
        subject.velocityInViewResult = .init(x: 0, y: 100)

        subject.touchesBegan(Set(), with: UIEvent())
        subject.touchesMoved([UITouch()], with: UIEvent())

        wait(for: [expectationHorizontal, expectationVertical], timeout: defaultTimeout)
    }

    // MARK: - touchesEnded

    func test_touchesEnded_callsExpectedHandler() {
        let expectation = expectation(description: "Touches ended handler called")
        subject.touchesEndedHandler = { expectation.fulfill() }

        subject.touchesEnded(Set(), with: UIEvent())

        wait(for: [expectation], timeout: defaultTimeout)
    }
}
