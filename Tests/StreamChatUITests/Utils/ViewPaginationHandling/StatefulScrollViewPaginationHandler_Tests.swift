//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class StatefulStatefulScrollViewPaginationHandler_Tests: XCTestCase {
    func test_whenScrollViewContentOffsetReachesContentSizeHeight_onNewBottomPageIsCalled() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 100

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewBottomPage = { _, _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetReachesContentSizeHeightMultipleTimes_onNewBottomPageIsCalledOnce() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 100

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        var receivedCompletion: ((Error?) -> Void)?

        sut.onNewBottomPage = { notifyItemCount, completion in
            notifyItemCount(0)
            receivedCompletion = completion
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)

        // Calling updateElementsCount with the same items count has no effect
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 150)
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 200)

        waitForExpectations(timeout: defaultTimeout)

        // We complete first new page request
        receivedCompletion?(nil)
        sut.updateElementsCount(with: 10)

        let exp2 = expectation(description: "on new top page closure can be called again")

        sut.onNewBottomPage = { _, _ in
            exp2.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 250)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetReachesContentSizeHeightMultipleTimes_ifRequestRetursError_newTopPageCanBeCalledAgain() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 100

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        var receivedCompletion: ((Error?) -> Void)?

        sut.onNewBottomPage = { notifyItemCount, completion in
            notifyItemCount(0)
            receivedCompletion = completion
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 100)

        // Calling updateElementsCount with the same items count has no effect
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 150)
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 200)

        waitForExpectations(timeout: defaultTimeout)

        // We complete first new page request with an error, which enables subsequent calls. No need to call `updateElementsCount`
        receivedCompletion?(NSError(domain: "", code: 0))

        let exp2 = expectation(description: "on new top page closure can be called again")

        sut.onNewBottomPage = { _, _ in
            exp2.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 250)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetWithinBottomThreshold_onNewBottomPageIsCalled() {
        let exp = expectation(description: "on new bottom page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.bottomThreshold = 100
        sut.onNewBottomPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.bottomThreshold = 100
        sut.onNewBottomPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.bottomThreshold = 100
        sut.onNewBottomPage = { _, _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 890)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetReachesZero_onNewTopPageIsCalled() {
        let exp = expectation(description: "on new top page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize = .init(width: 50, height: 50)

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = { _, _ in
            exp.fulfill()
        }

        scrollView.contentOffset = .zero

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetWithinTopThreshold_whenIsScrollingTop_onNewTopPageIsCalled() {
        let exp = expectation(description: "on new top page closure is called")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        sut.onNewTopPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        var receivedCompletion: ((Error?) -> Void)?
        sut.onNewTopPage = { notifyItemCount, completion in
            notifyItemCount(0)
            receivedCompletion = completion
            exp.fulfill()
        }

        // Simulate previous position (Scrolling top)
        scrollView.contentOffset = .init(x: 0, y: 120)

        // Calling updateElementsCount with the same items count has no effect
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 90)
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 80)

        waitForExpectations(timeout: defaultTimeout)

        // We complete first new page request
        receivedCompletion?(nil)
        sut.updateElementsCount(with: 10)

        let exp2 = expectation(description: "on new top page closure can be called again")

        sut.onNewTopPage = { _, _ in
            exp2.fulfill()
        }

        scrollView.contentOffset = .init(x: 0, y: 60)

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_whenScrollViewContentOffsetWithinTopThreshold_whenIsScrollingTopMultipleTimes_ifRequestRetursError_newTopPageCanBeCalledAgain() {
        let exp = expectation(description: "on new top page closure is called once")
        let scrollView = MockScrollView()
        scrollView.contentSize.height = 1000

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        var receivedCompletion: ((Error?) -> Void)?
        sut.onNewTopPage = { notifyItemCount, completion in
            notifyItemCount(0)
            receivedCompletion = completion
            exp.fulfill()
        }

        // Simulate previous position (Scrolling top)
        scrollView.contentOffset = .init(x: 0, y: 120)

        // Calling updateElementsCount with the same items count has no effect
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 90)
        sut.updateElementsCount(with: 0)
        scrollView.contentOffset = .init(x: 0, y: 80)

        waitForExpectations(timeout: defaultTimeout)

        // We complete first new page request with an error, which enables subsequent calls. No need to call `updateElementsCount`
        receivedCompletion?(NSError(domain: "", code: 0))

        let exp2 = expectation(description: "on new top page closure can be called again")

        sut.onNewTopPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        sut.onNewTopPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.topThreshold = 100
        sut.onNewTopPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewBottomPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewTopPage = { _, _ in
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

        let sut = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        sut.onNewBottomPage = { _, _ in
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
