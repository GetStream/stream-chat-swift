//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

/// For inverted list views, we switch the top with the bottom and vice-versa.
final class InvertedListViewPaginationHandler: ViewPaginationHandling {
    private var paginationHandler: ViewPaginationHandling

    init(paginationHandler: ViewPaginationHandling) {
        self.paginationHandler = paginationHandler
    }

    var topThreshold: Int {
        get {
            paginationHandler.bottomThreshold
        }
        set {
            paginationHandler.bottomThreshold = newValue
        }
    }

    var bottomThreshold: Int {
        get {
            paginationHandler.topThreshold
        }
        set {
            paginationHandler.topThreshold = newValue
        }
    }

    var onNewTopPage: (() -> Void)? {
        get {
            paginationHandler.onNewBottomPage
        }
        set {
            paginationHandler.onNewBottomPage = newValue
        }
    }

    var onNewBottomPage: (() -> Void)? {
        get {
            paginationHandler.onNewTopPage
        }
        set {
            paginationHandler.onNewTopPage = newValue
        }
    }

    func willDisplayItem(at indexPath: IndexPath, totalItemsCount: Int) {
        paginationHandler.willDisplayItem(at: indexPath, totalItemsCount: totalItemsCount)
    }
}
