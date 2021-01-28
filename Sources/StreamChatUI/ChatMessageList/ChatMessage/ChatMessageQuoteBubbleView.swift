//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageQuoteBubbleView = _ChatMessageQuoteBubbleView<NoExtraData>

open class _ChatMessageQuoteBubbleView<ExtraData: ExtraDataTypes>: _ChatMessageComposerQuoteBubbleView<ExtraData> {
    public var isParentMessageSentByCurrentUser: Bool? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        containerConstraints.forEach {
            $0.constant = 0
        }
    }
    
    override open func updateContent() {
        super.updateContent()
        
        guard let isParentMessageSentByCurrentUser = isParentMessageSentByCurrentUser else { return }
        authorAvatarView.removeFromSuperview()
        
        contentView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            isParentMessageSentByCurrentUser ? .layerMaxXMaxYCorner : .layerMinXMaxYCorner
        ]
    
        if isParentMessageSentByCurrentUser {
            contentView.backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            container.insertArrangedSubview(authorAvatarView, at: 0)
        } else {
            contentView.backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBackground
            container.addArrangedSubview(authorAvatarView)
        }
    }
}
