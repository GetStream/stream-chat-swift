//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A Button that is used to indicate unread messages in the Message list.
open class ScrollToLatestMessageButton: _Button, ThemeProvider {
    /// The unread count that will be shown on the button as a badge icon.
    var content: ChannelUnreadCount = .noUnread {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    /// The view showing number of unread messages in channel if any.
    open private(set) lazy var unreadCountView: ChatMessageListUnreadCountView = components
        .messageListUnreadCountView
        .init()
        .withoutAutoresizingMaskConstraints
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height / 2
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        setImage(appearance.images.scrollDownArrow, for: .normal)
        backgroundColor = appearance.colorPalette.background8
        layer.addShadow(color: appearance.colorPalette.shadow)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        addSubview(unreadCountView)
        unreadCountView.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
        unreadCountView.centerYAnchor.pin(equalTo: topAnchor).isActive = true
    }
    
    override open func updateContent() {
        super.updateContent()
        
        unreadCountView.content = content
        unreadCountView.invalidateIntrinsicContentSize()
    }
}
