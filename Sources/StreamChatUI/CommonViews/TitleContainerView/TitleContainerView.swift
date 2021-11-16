//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays a title label and subtitle in a container stack view.
open class TitleContainerView: _View, AppearanceProvider, SwiftUIRepresentable {
    /// Content of the view that contains title (first line) and subtitle (second nil)
    open var content: (title: String?, subtitle: String?) = (nil, nil) {
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
    
    /// A view that acts as the main container for the subviews
    open private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        titleLabel.textAlignment = .center
        titleLabel.font = appearance.fonts.headlineBold
        titleLabel.textColor = .white//appearance.colorPalette.text

        subtitleLabel.textAlignment = .center
        subtitleLabel.font = appearance.fonts.caption1
        subtitleLabel.textColor = .white//appearance.colorPalette.subtitleText
    }
    
    override open func setUp() {
        super.setUp()
        
        containerView.axis = .vertical
        containerView.alignment = .center
        containerView.spacing = 0
    }
    
    override open func setUpLayout() {
        super.setUpLayout()

        containerView.addArrangedSubviews([titleLabel, subtitleLabel])
        embed(containerView)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        titleLabel.isHidden = content.title == nil
        titleLabel.text = content.title
        
        subtitleLabel.isHidden = content.subtitle == nil
        subtitleLabel.text = content.subtitle
    }
}
