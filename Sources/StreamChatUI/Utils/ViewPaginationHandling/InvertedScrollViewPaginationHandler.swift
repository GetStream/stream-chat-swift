//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// For inverted scroll views, we switch the top with the bottom and vice-versa.
final class InvertedScrollViewPaginationHandler: StatefulViewPaginationHandling {
    private let scrollViewPaginationHandler: StatefulScrollViewPaginationHandler

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

    var onNewTopPage: StatefulViewPaginationHandlingBlock? {
        get {
            scrollViewPaginationHandler.onNewBottomPage
        }
        set {
            scrollViewPaginationHandler.onNewBottomPage = newValue
        }
    }

    var onNewBottomPage: StatefulViewPaginationHandlingBlock? {
        get {
            scrollViewPaginationHandler.onNewTopPage
        }
        set {
            scrollViewPaginationHandler.onNewTopPage = newValue
        }
    }

    init(scrollViewPaginationHandler: StatefulScrollViewPaginationHandler) {
        self.scrollViewPaginationHandler = scrollViewPaginationHandler
    }

    func updateElementsCount(with newCount: Int) {
        scrollViewPaginationHandler.updateElementsCount(with: newCount)
    }

    /// Factory method to easily create an instance with the required dependencies.
    static func make(scrollView: UIScrollView) -> InvertedScrollViewPaginationHandler {
        let paginationHandler = StatefulScrollViewPaginationHandler(scrollView: scrollView)
        return InvertedScrollViewPaginationHandler(scrollViewPaginationHandler: paginationHandler)
    }
}
