//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

typealias ChatChannelListEmptyView = _ChatChannelListEmptyView<NoExtraData>

class _ChatChannelListEmptyView<ExtraData>: _View {
    open var didTapActionButton: (() -> Void)?
    
    open lazy var mainContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
    open lazy var mainImageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    open lazy var titleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    open lazy var subtitleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    open lazy var actionButton: UIButton = UIButton(type: .system).withoutAutoresizingMaskConstraints
    
    override func setUp() {
        super.setUp()
        
        titleLabel.text = L10n.Channellist.LoadingIndicator.Empty.title
        subtitleLabel.text = L10n.Channellist.LoadingIndicator.Empty.subtitle
        actionButton.setTitle(L10n.Channellist.LoadingIndicator.Empty.button, for: .normal)
    }
    
    override func setUpLayout() {
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
    
    override func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = Appearance.default.colorPalette.background
        
        mainImageView.image = Appearance.default.images.message
        mainImageView.tintColor = Appearance.default.colorPalette.background2
        
        mainContainer.axis = .vertical
        mainContainer.alignment = .center
        
        titleLabel.font = Appearance.default.fonts.bodyBold
        titleLabel.textAlignment = .center
        
        subtitleLabel.font = Appearance.default.fonts.subheadline
        subtitleLabel.textColor = Appearance.default.colorPalette.subtitleText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        
        actionButton.titleLabel?.font = Appearance.default.fonts.bodyBold
    }
}
