//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays a title label and subtitle in a container stack view.
open class TitleContainerView: _View, AppearanceProvider, SwiftUIRepresentable {
    /// Content of the view that contains title (first line) and subtitle (second nil)
    open var content: (title: String?, subtitle: String?, isOneWayChannel: Bool, isMute: Bool) = (nil, nil, false, false) {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    /// Label that represents the first line of the view
    open private(set) lazy var titleLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
    
    /// Label that represents the second line of the view
    open private(set) lazy var subtitleLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
    
    /// image that represent channel mute status
    open private(set) lazy var muteImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = appearance.images.muteChannel
        imageView.tintColor = .gray
        imageView.withoutAutoresizingMaskConstraints
        return imageView
    }()
    
    /// A view that acts as the main container for the subviews
    open private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    /// A view that acts as the title container for the subviews
    open private(set) lazy var titleContainerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        titleLabel.textAlignment = .center
        titleLabel.font = appearance.fonts.headlineBold
        titleLabel.textColor = appearance.colorPalette.chatNavigationTitleColor

        subtitleLabel.textAlignment = .center
        subtitleLabel.font = appearance.fonts.caption1
        subtitleLabel.textColor = appearance.colorPalette.chatNavigationTitleColor
    }
    
    override open func setUp() {
        super.setUp()
        
        containerView.axis = .vertical
        containerView.alignment = .center
        containerView.spacing = 0
        
        titleContainerView.axis = .horizontal
        titleContainerView.alignment = .center
        titleContainerView.spacing = 2
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        titleContainerView.removeAllArrangedSubviews()
        if content.isMute {
            titleContainerView.addArrangedSubviews([titleLabel, muteImageView])
        } else {
            titleContainerView.addArrangedSubviews([titleLabel])
        }
        containerView.addArrangedSubviews([titleContainerView, subtitleLabel])
        containerView.spacing = 3
        embed(containerView)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        titleLabel.isHidden = content.title == nil
        titleLabel.text = content.title
        if content.isOneWayChannel {
            subtitleLabel.isHidden = true
        } else {
            subtitleLabel.isHidden = content.subtitle == nil
            subtitleLabel.text = content.subtitle
        }
    }

    open func updateSubtitle(isHide: Bool) {
        self.subtitleLabel.alpha = isHide ? 0 : 1
    }
}
