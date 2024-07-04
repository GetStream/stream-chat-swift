//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The thread list error view that is shown when loading threads fails.
open class ChatThreadListErrorView: _View, ThemeProvider {
    /// The banner view that displays the error text and the refresh button.
    open private(set) lazy var bannerView = BannerView()
        .withoutAutoresizingMaskConstraints

    /// The refresh button responsible to trigger a thread list refresh.
    public var refreshButton: UIButton {
        bannerView.actionButton
    }

    /// The closure which is triggered whenever the action button is tapped.
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

        bannerView.textLabel.text = L10n.ThreadList.Error.message
        bannerView.actionButton.setImage(appearance.images.restart, for: .normal)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(bannerView)
        bannerView.heightAnchor.pin(equalToConstant: 56).isActive = true
    }
}
