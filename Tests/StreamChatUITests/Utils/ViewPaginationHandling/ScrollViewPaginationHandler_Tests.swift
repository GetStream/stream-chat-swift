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
        sut.onNewBottomPage = {
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetWithinBottomThreshold_onNewBottomPageIsCalled() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.bottomThreshold = 100
        sut.onNewBottomPage = {
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
        sut.onNewBottomPage = {
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 890)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetReachesZero_onNewTopPageIsCalled() {
        let exp = expectation(description: "on new top page closure is called")
        let scrollView = MockScrollView()

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = {
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
        sut.onNewTopPage = {
            exp.fulfill()
        }

        // Simulate previous position (Scrolling top)
        scrollView.contentOffset = .init(x: 0, y: 120)
        
        scrollView.contentOffset = .init(x: 0, y: 90)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetNotInTopThreshold__whenIsScrollingTop_onNewTopPageIsNotCalled() {
        let exp = expectation(description: "on new top page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        sut.onNewTopPage = {
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
        sut.onNewTopPage = {
            exp.fulfill()
        }

        // Simulate previous position already in top
        scrollView.contentOffset = .init(x: 0, y: 50)

        scrollView.contentOffset = .init(x: 0, y: 90)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewIsTrackingOrDecelerating_onNewBottomPageNotCalled() {}

    func test_whenScrollViewNotIsTrackingOrDecelerating_onNewTopPageNotCalled() {
        let exp = expectation(description: "on new top page closure is called")
        exp.isInverted = true
        let scrollView = MockScrollView()
        scrollView.isTrackingOrDeceleratingMocked = false

        let sut = ScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = {
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
        sut.onNewBottomPage = {
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
