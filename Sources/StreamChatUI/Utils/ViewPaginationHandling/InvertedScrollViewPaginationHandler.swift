//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

/// For inverted scroll views, we switch the top with the bottom and vice-versa.
class InvertedScrollViewPaginationHandler: ViewPaginationHandling {
    private let scrollViewPaginationHandler: ScrollViewPaginationHandler

    var topThreshold: Int {
        get {
            scrollViewPaginationHandler.bottomThreshold
        }
        set {
            scrollViewPaginationHandler.bottomThreshold = newValue
        }
    }

    var bottomThreshold: Int {
        get {
            scrollViewPaginationHandler.topThreshold
        }
        set {
            scrollViewPaginationHandler.topThreshold = newValue
        }
    }

    var onNewTopPage: (() -> Void)? {
        get {
            scrollViewPaginationHandler.onNewBottomPage
        }
        set {
            scrollViewPaginationHandler.onNewBottomPage = newValue
        }
    }

    var onNewBottomPage: (() -> Void)? {
        get {
            scrollViewPaginationHandler.onNewTopPage
        }
        set {
            scrollViewPaginationHandler.onNewTopPage = newValue
        }
    }

    init(scrollViewPaginationHandler: ScrollViewPaginationHandler) {
        self.scrollViewPaginationHandler = scrollViewPaginationHandler
    }

    /// Factory method to easily create an instance with the required dependencies.
    static func make(scrollView: UIScrollView) -> InvertedScrollViewPaginationHandler {
        let paginationHandler = ScrollViewPaginationHandler(scrollView: scrollView)
        return InvertedScrollViewPaginationHandler(scrollViewPaginationHandler: paginationHandler)
    }
}
