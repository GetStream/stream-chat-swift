//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelListErrorView: _View, ThemeProvider {
    /// Container which holds the elements on the error banner.
    open private(set) lazy var container: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
    /// Label describing there has been an error.
    open private(set) lazy var titleLabel: UILabel = UILabel().withBidirectionalLanguagesSupport.withoutAutoresizingMaskConstraints
    /// Retry button which is located at the trailing of the view.
    open private(set) lazy var retryButton: UIButton = UIButton().withoutAutoresizingMaskConstraints
    /// Spacing view so the button has some spacing with bidirectional language support.
    open private(set) lazy var spacer: UIView = UIView().withoutAutoresizingMaskConstraints
    
    open var refreshButtonAction: (() -> Void)?
    
    override open func setUp() {
        super.setUp()

        titleLabel.text = L10n.ChannelList.Error.message
        retryButton.addTarget(self, action: #selector(didTapRetryButton), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        retryButton.setImage(appearance.images.restart, for: .normal)
        backgroundColor = appearance.colorPalette.textLowEmphasis
        titleLabel.textColor = appearance.colorPalette.staticColorText
        retryButton.tintColor = appearance.colorPalette.staticColorText
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
        addSubview(container)
        container.pin(anchors: [.leading, .trailing, .top], to: layoutMarginsGuide)
        container.bottomAnchor.pin(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
        container.axis = .horizontal
        container.alignment = .center
        container.addArrangedSubviews([titleLabel, spacer, retryButton])
    }

    @objc open func didTapRetryButton() {
        refreshButtonAction?()
    }
}
