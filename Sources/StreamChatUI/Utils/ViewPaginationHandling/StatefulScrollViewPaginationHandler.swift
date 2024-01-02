//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// A component responsible to handle when to load new pages in a scrollView holding state associated to the content view
final class StatefulScrollViewPaginationHandler: StatefulViewPaginationHandling {
    private var bottomPageRequestItemCount: Int?
    private var topPageRequestItemCount: Int?
    private var canRequestNewTopPage: Bool {
        topPageRequestItemCount == nil
    }

    private var canRequestNewBottomPage: Bool {
        bottomPageRequestItemCount == nil
    }

    private weak var scrollView: UIScrollView?
    private var observation: NSKeyValueObservation?
    private var previousPosition: CGFloat = 0.0

    var topThreshold: Int = 100
    var bottomThreshold: Int = 400

    var onNewTopPage: StatefulViewPaginationHandlingBlock?
    var onNewBottomPage: StatefulViewPaginationHandlingBlock?

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
        if canRequestNewBottomPage, position > scrollView.contentSize.height - bottomThreshold - scrollView.frame.size.height {
            onNewBottomPage?({ bottomPageRequestItemCount = $0 }, { [weak self] error in
                if error != nil {
                    self?.bottomPageRequestItemCount = nil
                }
            })
        }

        let topThreshold = CGFloat(topThreshold)
        if canRequestNewTopPage, position >= 0 && position <= topThreshold && position <= max(0, previousPosition) {
            onNewTopPage?({ topPageRequestItemCount = $0 }, { [weak self] error in
                if error != nil {
                    self?.topPageRequestItemCount = nil
                }
            })
        }

        previousPosition = position
    }

    func updateElementsCount(with newCount: Int) {
        var shouldReset = false
        if let topCount = topPageRequestItemCount, topCount != newCount {
            shouldReset = true
        } else if let bottomCount = bottomPageRequestItemCount, bottomCount != newCount {
            shouldReset = true
        }
        guard shouldReset else { return }

        topPageRequestItemCount = nil
        bottomPageRequestItemCount = nil
    }

    deinit {
        observation?.invalidate()
    }
}
