//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

/// A component responsible to handle when to load new pages in a scrollView.
final class ListViewPaginationHandler: ViewPaginationHandling {
    private weak var scrollView: UIScrollView?
    private var previousIndexPath: IndexPath = .init(item: 0, section: 0)

    /// From which item it should start prefetching more data at the top.
    var topThreshold: Int = 10
    /// From which item it should start prefetching more data at the bottom.
    var bottomThreshold: Int = 10

    var onNewTopPage: (() -> Void)?
    var onNewBottomPage: (() -> Void)?

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    func willDisplayItem(at indexPath: IndexPath, totalItemsCount: Int) {
        let item = indexPath.item
        let lastItem = totalItemsCount - 1
        let isScrollingBottom = item > previousIndexPath.item
        let isScrollingTop = !isScrollingBottom

        guard scrollView?.isTrackingOrDecelerating == true else {
            return
        }

        if item >= 0 && item <= topThreshold && isScrollingTop {
            onNewTopPage?()
        } else if item >= lastItem - bottomThreshold && item <= lastItem && isScrollingBottom {
            onNewBottomPage?()
        }

        previousIndexPath = indexPath
    }
}
