//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelListEmptyView: _View, ThemeProvider {
    /// Container which holds all elements except action button in this view.
    open private(set) lazy var container: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
    /// Icon ImageView which is displayed above the title label.
    open private(set) lazy var iconView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    /// Title label which displays the main message for the empty view.
    open private(set) lazy var titleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    /// Subtitle label which displays additional information for the empty view.
    open private(set) lazy var subtitleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    /// Button for an additional action on the empty view. E.g. start a new chat.
    open private(set) lazy var actionButton: UIButton = UIButton(type: .system).withoutAutoresizingMaskConstraints
    
    public var actionButtonPressed: (() -> Void)?
    
    override open func setUp() {
        super.setUp()
        
        titleLabel.text = L10n.ChannelList.Empty.title
        subtitleLabel.text = L10n.ChannelList.Empty.subtitle
        actionButton.setTitle(L10n.ChannelList.Empty.button, for: .normal)
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        directionalLayoutMargins = .init(top: 8, leading: 32, bottom: 8, trailing: 32)
        
        addSubview(container)
        container.pin(anchors: [.centerX, .centerY], to: self)
        container.pin(anchors: [.leading, .trailing], to: layoutMarginsGuide)
        container.axis = .vertical
        container.alignment = .center
        container.addArrangedSubviews([iconView, titleLabel, subtitleLabel])
        
        addSubview(actionButton)
        NSLayoutConstraint.activate([
            actionButton.centerXAnchor.pin(equalTo: container.centerXAnchor),
            actionButton.topAnchor.pin(greaterThanOrEqualTo: container.bottomAnchor, constant: 10),
            actionButton.bottomAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.background
        
        iconView.image = appearance.images.emptyChannelListMessageBubble
        
        titleLabel.font = appearance.fonts.bodyBold
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.textAlignment = .center
        
        subtitleLabel.font = appearance.fonts.subheadline
        subtitleLabel.textColor = appearance.colorPalette.subtitleText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        
        actionButton.titleLabel?.font = appearance.fonts.bodyBold
    }
    
    @objc open func didTapActionButton() {
        actionButtonPressed?()
    }
}
