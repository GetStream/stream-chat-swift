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
    
    /// Value of `channelListErrorView` height constraint.
    open var channelListErrorViewHeight: CGFloat { 88 }
    
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

        heightAnchor.pin(equalToConstant: channelListErrorViewHeight).isActive = true
        directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
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
    
    /// Shows the error view.
    open func show() {
        center = .init(x: center.x, y: center.y + channelListErrorViewHeight)
        isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            self.center = .init(x: self.center.x, y: self.center.y - self.channelListErrorViewHeight)
            self.layoutSubviews()
        }
    }
    
    /// Hides the error view.
    open func hide() {
        if isHidden { return }
        UIView.animate(withDuration: 0.5) {
            self.center = .init(x: self.center.x, y: self.center.y + self.channelListErrorViewHeight)
            self.layoutSubviews()
        } completion: { _ in
            self.isHidden = true
        }
    }
}
