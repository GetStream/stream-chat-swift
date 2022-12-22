//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A component responsible to handle when to load new pages in a scrollView.
class ScrollViewPaginationHandler: ViewPaginationHandling {
    private weak var scrollView: UIScrollView?
    private var observation: NSKeyValueObservation?
    private var previousPosition: CGFloat = 0.0

    var topThreshold: Int = 100
    var bottomThreshold: Int = 250

    var onNewTopPage: (() -> Void)?
    var onNewBottomPage: (() -> Void)?

    init(scrollView: UIScrollView?) {
        self.scrollView = scrollView

        observation = self.scrollView?.observe(\.contentOffset, changeHandler: { [weak self] scrollView, _ in
            self?.onChanged(scrollView)
        })
    }

    private func onChanged(_ scrollView: UIScrollView) {
        guard scrollView.isTrackingOrDecelerating else {
            return
        }

        let position = scrollView.contentOffset.y
        if position > scrollView.contentSize.height - CGFloat(bottomThreshold) - scrollView.frame.size.height {
            onNewBottomPage?()
        }

        if position >= 0 && position <= CGFloat(topThreshold) && position <= max(0, previousPosition) {
            onNewTopPage?()
        }

        previousPosition = position
    }

    deinit {
        observation?.invalidate()
    }
}
