//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// View that is displayed as top overlay when message list is scrolling
open class ChatMessageListScrollOverlayView: _View, AppearanceProvider {
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }
    
    open lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.adjustsFontForContentSizeCategory = true
        return textLabel.withoutAutoresizingMaskConstraints
    }()
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        embed(textLabel, insets: NSDirectionalEdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9))
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        layer.cornerRadius = bounds.height / 2
        
        backgroundColor = appearance.colorPalette.background7
        
        textLabel.font = appearance.fonts.footnote
        textLabel.textColor = appearance.colorPalette.staticColorText
    }
    
    override open func updateContent() {
        super.updateContent()
        
        textLabel.text = content
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
