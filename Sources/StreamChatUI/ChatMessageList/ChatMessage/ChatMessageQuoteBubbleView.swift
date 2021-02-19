//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageQuoteBubbleView = _ChatMessageQuoteBubbleView<NoExtraData>

internal class _ChatMessageQuoteBubbleView<ExtraData: ExtraDataTypes>: _ChatMessageComposerQuoteBubbleView<ExtraData> {
    internal var isParentMessageSentByCurrentUser: Bool? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    override internal func setUpLayout() {
        super.setUpLayout()
        
        containerConstraints.forEach {
            $0.constant = 0
        }
    }
    
    override internal func updateContent() {
        super.updateContent()
        
        guard let isParentMessageSentByCurrentUser = isParentMessageSentByCurrentUser else { return }
        authorAvatarView.removeFromSuperview()
        
        contentView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            isParentMessageSentByCurrentUser ? .layerMaxXMaxYCorner : .layerMinXMaxYCorner
        ]
    
        if isParentMessageSentByCurrentUser {
            contentView.backgroundColor = uiConfig.colorPalette.background1
            container.insertArrangedSubview(authorAvatarView, at: 0)
        } else {
            contentView.backgroundColor = uiConfig.colorPalette.background1
            container.addArrangedSubview(authorAvatarView)
        }
    }
}
