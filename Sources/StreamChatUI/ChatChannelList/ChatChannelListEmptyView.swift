//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelListEmptyView: _View, ThemeProvider {
    public var buttonAction: (() -> Void)?
    
    /// Main container which holds all elements except action button in this view.
    open lazy var mainContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
    /// ImageView which is displayed above the title label.
    open lazy var mainImageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    /// Title label for the view.
    open lazy var titleLabel: UILabel = UILabel().withBidirectionalLanguagesSupport.withoutAutoresizingMaskConstraints
    /// Subtitle label.
    open lazy var subtitleLabel: UILabel = UILabel().withBidirectionalLanguagesSupport.withoutAutoresizingMaskConstraints
    /// Button which has some action
    open lazy var actionButton: UIButton = UIButton(type: .system).withoutAutoresizingMaskConstraints
    
    override open func setUp() {
        super.setUp()
        
        titleLabel.text = L10n.Channellist.LoadingIndicator.Empty.title
        subtitleLabel.text = L10n.Channellist.LoadingIndicator.Empty.subtitle
        actionButton.setTitle(L10n.Channellist.LoadingIndicator.Empty.button, for: .normal)
        actionButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        directionalLayoutMargins = .init(top: 8, leading: 30, bottom: 8, trailing: 30)
        addSubview(mainContainer)
        
        mainContainer.pin(anchors: [.centerX, .centerY], to: self)
        mainContainer.pin(anchors: [.leading, .trailing], to: layoutMarginsGuide)
        
        mainContainer.addArrangedSubviews([mainImageView, titleLabel, subtitleLabel])
        
        addSubview(actionButton)
        actionButton.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        actionButton.topAnchor.pin(greaterThanOrEqualTo: mainContainer.bottomAnchor).isActive = true
        actionButton.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.background
        
        mainImageView.image = appearance.images.message
        mainImageView.tintColor = appearance.colorPalette.background2
        
        mainContainer.axis = .vertical
        mainContainer.alignment = .center
        
        titleLabel.font = appearance.fonts.bodyBold
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.textAlignment = .center
        
        subtitleLabel.font = appearance.fonts.subheadline
        subtitleLabel.textColor = appearance.colorPalette.subtitleText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        
        actionButton.titleLabel?.font = appearance.fonts.bodyBold
    }
    
    @objc func didTapButton() {
        buttonAction?()
    }
}
