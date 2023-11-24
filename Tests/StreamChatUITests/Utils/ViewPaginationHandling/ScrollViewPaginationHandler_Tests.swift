//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ScrollViewPaginationHandler_Tests: XCTestCase {
    func test_whenScrollViewContentOffsetReachesContentSizeHeight_onNewBottomPageIsCalled() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 100

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewBottomPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetReachesContentSizeHeightMultipleTimes_onNewBottomPageIsCalledOnce() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 100

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        var receivedCompletion: (() -> Void)?
        sut.onNewBottomPage = { completion in
            receivedCompletion = completion
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)
        scrollView.contentOffset = .init(x: 0, y: 150)
        scrollView.contentOffset = .init(x: 0, y: 200)

        waitForExpectations(timeout: defaultTimeout)

        // We complete first new page request
        receivedCompletion?()

        let exp2 = expectation(description: "on new top page closure can be called again")

        sut.onNewBottomPage = { _ in
            exp2.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 250)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetWithinBottomThreshold_onNewBottomPageIsCalled() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.bottomThreshold = 100
        sut.onNewBottomPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 910)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentSizeIsZero_onNewBottomPageIsNotCalled() {
        let exp = expectation(description: "on new bottom page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 0

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.bottomThreshold = 100
        sut.onNewBottomPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 910)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetNotInBottomThreshold_onNewBottomPageIsNotCalled() {
        let exp = expectation(description: "on new bottom page closure is not called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.bottomThreshold = 100
        sut.onNewBottomPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 890)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetReachesZero_onNewTopPageIsCalled() {
        let exp = expectation(description: "on new top page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize = .init(width: 50, height: 50)

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .zero

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetWithinTopThreshold_whenIsScrollingTop_onNewTopPageIsCalled() {
        let exp = expectation(description: "on new top page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        sut.onNewTopPage = { _ in
            exp.fulfill()
        }

        // Simulate previous position (Scrolling top)
        scrollView.contentOffset = .init(x: 0, y: 120)
        
        scrollView.contentOffset = .init(x: 0, y: 90)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetWithinTopThreshold_whenIsScrollingTopMultipleTimes_onNewTopPageIsCalledOnce() {
        let exp = expectation(description: "on new top page closure is called once")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        var receivedCompletion: (() -> Void)?
        sut.onNewTopPage = { completion in
            receivedCompletion = completion
            exp.fulfill()
        }

        // Simulate previous position (Scrolling top)
        scrollView.contentOffset = .init(x: 0, y: 120)

        scrollView.contentOffset = .init(x: 0, y: 90)
        scrollView.contentOffset = .init(x: 0, y: 80)
        scrollView.contentOffset = .init(x: 0, y: 70)

        waitForExpectations(timeout: defaultTimeout)

        // We complete first new page request
        receivedCompletion?()

        let exp2 = expectation(description: "on new top page closure can be called again")

        sut.onNewTopPage = { _ in
            exp2.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 60)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetNotInTopThreshold__whenIsScrollingTop_onNewTopPageIsNotCalled() {
        let exp = expectation(description: "on new top page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        sut.onNewTopPage = { _ in
            exp.fulfill()
        }

        // Simulate previous position (Scrolling top)
        scrollView.contentOffset = .init(x: 0, y: 120)

        scrollView.contentOffset = .init(x: 0, y: 105)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetInTopThreshold__whenIsScrollingDown_onNewTopPageIsNotCalled() {
        let exp = expectation(description: "on new top page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        sut.onNewTopPage = { _ in
            exp.fulfill()
        }

        // Simulate previous position already in top
        scrollView.contentOffset = .init(x: 0, y: 50)

        scrollView.contentOffset = .init(x: 0, y: 90)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentSizeIsZero_onNewTopPageNotCalled() {
        let exp = expectation(description: "on new top page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize = .init(width: 0, height: 0)

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .zero

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewIsTrackingOrDecelerating_onNewBottomPageNotCalled() {
        let exp = expectation(description: "on new top page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 100
        scrollView.isTrackingOrDeceleratingMocked = false

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewBottomPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewNotIsTrackingOrDecelerating_onNewTopPageNotCalled() {
        let exp = expectation(description: "on new top page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize = .init(width: 0, height: 50)
        scrollView.isTrackingOrDeceleratingMocked = false

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .zero

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewIsWithinTopThreshold_whenIsSrollingToBottom_onNewTopPageNotCalled() {
        let exp = expectation(description: "on new bottom page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.isTrackingOrDeceleratingMocked = false
        scrollView.contentSize.height = 100

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewBottomPage = { _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)

        waitForExpectations(timeout: defaultTimeout)
    }
}

private class MockScrollView: UIScrollView {
    var isTrackingOrDeceleratingMocked: Bool? = true

    override var isTracking: Bool {
        isTrackingOrDeceleratingMocked ?? super.isTracking
    }

    override var isDecelerating: Bool {
        isTrackingOrDeceleratingMocked ?? super.isDecelerating
    }
}
