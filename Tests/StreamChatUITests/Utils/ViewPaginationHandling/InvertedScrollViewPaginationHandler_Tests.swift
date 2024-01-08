//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class InvertedScrollViewPaginationHandler_Tests: XCTestCase {
    func test_topThreshold_shouldReturnBottomThresholdOfRegularPaginationHandler() {
        let scrollViewPaginationHandler = StatefulScrollViewPaginationHandler(scrollView: UIScrollView())
        scrollViewPaginationHandler.bottomThreshold = 150
        let sut = InvertedScrollViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        XCTAssertEqual(sut.topThreshold, 150)
    }

    func test_onNewTopPage_shouldBeCalledWhenNewBottomPageIsCalled() {
        let exp = expectation(description: "should call on new top page")
        let scrollViewPaginationHandler = StatefulScrollViewPaginationHandler(scrollView: UIScrollView())
        let sut = InvertedScrollViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        sut.onNewTopPage = { _, _ in
            exp.fulfill()
        }

        scrollViewPaginationHandler.onNewBottomPage?({ _ in }, { _ in })

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_bottomThreshold_shouldReturnTopThresholdOfRegularPaginationHandler() {
        let scrollViewPaginationHandler = StatefulScrollViewPaginationHandler(scrollView: UIScrollView())
        scrollViewPaginationHandler.topThreshold = 150
        let sut = InvertedScrollViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        XCTAssertEqual(sut.bottomThreshold, 150)
    }

    func test_onNewBottomPage_shouldBeCalledWhenNewTopPageIsCalled() {
        let exp = expectation(description: "should call on new bottom page")
        let scrollViewPaginationHandler = StatefulScrollViewPaginationHandler(scrollView: UIScrollView())
        let sut = InvertedScrollViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        sut.onNewBottomPage = { _, _ in
            exp.fulfill()
        }

        scrollViewPaginationHandler.onNewTopPage?({ _ in }, { _ in })

        waitForExpectations(timeout: defaultTimeout)
    }
}
