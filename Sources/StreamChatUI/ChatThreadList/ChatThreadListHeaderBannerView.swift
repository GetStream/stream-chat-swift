//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The thread list header banner view shown by default as a table view header to fetch new threads.
open class ChatThreadListHeaderBannerView: _View, ThemeProvider {
    public struct Content {
        public var newThreadsCount: Int
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The banner view to show how many new threads are available.
    open private(set) lazy var bannerView = BannerView()
        .withoutAutoresizingMaskConstraints

    /// The refresh button responsible to fetch new threads.
    public var refreshButton: UIButton {
        bannerView.actionButton
    }

    /// The refresh action when tapping the refresh button.
    public var onAction: (() -> Void)? {
        get {
            bannerView.onAction
        }
        set {
            bannerView.onAction = newValue
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        bannerView.actionButton.setImage(appearance.images.restart, for: .normal)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(bannerView)
        bannerView.heightAnchor.pin(equalToConstant: 56).isActive = true
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        bannerView.textLabel.text = L10n.ThreadList.newThreads(content.newThreadsCount)
    }
}
