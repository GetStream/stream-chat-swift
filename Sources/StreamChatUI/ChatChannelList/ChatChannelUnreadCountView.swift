//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a number of unread messages in channel.
public typealias ChatChannelUnreadCountView = _ChatChannelUnreadCountView<NoExtraData>
/// A view that shows a number of unread messages in channel.
open class _ChatChannelUnreadCountView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    /// The `UILabel` instance that holds number of unread messages.
    open private(set) lazy var unreadCountLabel = UILabel().withoutAutoresizingMaskConstraints
    
    /// A `CGFloat`value that defines insets for embedding `unreadCountLabel`.
    open private(set) var inset: CGFloat = 3
    
    override open var intrinsicContentSize: CGSize {
        let height: CGFloat = max(unreadCountLabel.font.pointSize + inset * 2, frame.height)
        let width = max(unreadCountLabel.intrinsicContentSize.width + inset * 2, height)
        return .init(width: width, height: height)
    }
    
    open var content: ChannelUnreadCount = .noUnread {
        didSet { updateContentIfNeeded() }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        invalidateIntrinsicContentSize()
                
        layer.cornerRadius = intrinsicContentSize.height / 2
    }
        
    override public func defaultAppearance() {
        layer.masksToBounds = true
        backgroundColor = uiConfig.colorPalette.alert

        unreadCountLabel.textColor = uiConfig.colorPalette.staticColorText
        unreadCountLabel.font = uiConfig.font.footnoteBold
        
        unreadCountLabel.adjustsFontForContentSizeCategory = true
        unreadCountLabel.textAlignment = .center
    }

    override open func setUpLayout() {
        embed(unreadCountLabel, insets: .init(top: inset, leading: inset, bottom: inset, trailing: inset))
        setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
    }
    
    override open func updateContent() {
        isHidden = content.mentionedMessages == 0 && content.messages == 0
        unreadCountLabel.text = String(content.messages)
    }
}
