//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class InvertedScrollViewPaginationHandler_Tests: XCTestCase {
    func test_topThreshold_shouldReturnBottomThresholdOfRegularPaginationHandler() {
        let scrollViewPaginationHandler = ListViewPaginationHandler(scrollView: UIScrollView())
        scrollViewPaginationHandler.bottomThreshold = 150
        let sut = InvertedListViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        XCTAssertEqual(sut.topThreshold, 150)
    }

    func test_onNewTopPage_shouldBeCalledWhenNewBottomPageIsCalled() {
        let exp = expectation(description: "should call on new top page")
        let scrollViewPaginationHandler = ListViewPaginationHandler(scrollView: UIScrollView())
        let sut = InvertedListViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        sut.onNewTopPage = {
            exp.fulfill()
        }

        scrollViewPaginationHandler.onNewBottomPage?()

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_bottomThreshold_shouldReturnTopThresholdOfRegularPaginationHandler() {
        let scrollViewPaginationHandler = ListViewPaginationHandler(scrollView: UIScrollView())
        scrollViewPaginationHandler.topThreshold = 150
        let sut = InvertedListViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        XCTAssertEqual(sut.bottomThreshold, 150)
    }

    func test_onNewBottomPage_shouldBeCalledWhenNewTopPageIsCalled() {
        let exp = expectation(description: "should call on new bottom page")
        let scrollViewPaginationHandler = ListViewPaginationHandler(scrollView: UIScrollView())
        let sut = InvertedListViewPaginationHandler(scrollViewPaginationHandler: scrollViewPaginationHandler)

        sut.onNewBottomPage = {
            exp.fulfill()
        }

        scrollViewPaginationHandler.onNewTopPage?()

        waitForExpectations(timeout: defaultTimeout)
    }
}
