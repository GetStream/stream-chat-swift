//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

/// A component responsible to handle when to load new pages in a scrollView.
final class ScrollViewPaginationHandler: ViewPaginationHandling {
    private weak var scrollView: UIScrollView?
    private var observation: NSKeyValueObservation?
    private var previousPosition: CGFloat = 0.0

    private var isLoadingTopPage: Bool = false
    private var isLoadingBottomPage: Bool = false

    var topThreshold: Int = 100
    var bottomThreshold: Int = 400

    var onNewTopPage: ((@escaping () -> Void) -> Void)?
    var onNewBottomPage: ((@escaping () -> Void) -> Void)?

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView

        observation = self.scrollView?.observe(\.contentOffset, changeHandler: { [weak self] scrollView, _ in
            self?.onChanged(scrollView)
        })
    }

    private func onChanged(_ scrollView: UIScrollView) {
        guard scrollView.isTrackingOrDecelerating && scrollView.contentSize.height > 0 else {
            return
        }

        let bottomThreshold = CGFloat(bottomThreshold)
        let position = scrollView.contentOffset.y
        if !isLoadingBottomPage, position > scrollView.contentSize.height - bottomThreshold - scrollView.frame.size.height {
            isLoadingBottomPage = true
            onNewBottomPage? { [weak self] in
                self?.isLoadingBottomPage = false
            }
        }

        let topThreshold = CGFloat(topThreshold)
        if !isLoadingTopPage, position >= 0 && position <= topThreshold && position <= max(0, previousPosition) {
            isLoadingTopPage = true
            onNewTopPage? { [weak self] in
                self?.isLoadingTopPage = false
            }
        }

        previousPosition = position
    }

    deinit {
        observation?.invalidate()
    }
}
