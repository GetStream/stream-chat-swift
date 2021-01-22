//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageQuoteBubbleView<ExtraData: ExtraDataTypes>: MessageComposerQuoteBubbleView<ExtraData> {
    public var isParentMessageSentByCurrentUser: Bool? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        container.preservesSuperviewLayoutMargins = false
        container.isLayoutMarginsRelativeArrangement = false
    }
    
    override open func updateContent() {
        super.updateContent()
        
        guard let isParentMessageSentByCurrentUser = isParentMessageSentByCurrentUser else { return }
        authorAvatarView.removeFromSuperview()
        
        container.leftStackView.isHidden = !isParentMessageSentByCurrentUser
        container.rightStackView.isHidden = isParentMessageSentByCurrentUser
        
        container.centerStackView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            isParentMessageSentByCurrentUser ? .layerMaxXMaxYCorner : .layerMinXMaxYCorner
        ]
    
        if isParentMessageSentByCurrentUser {
            container.centerStackView.backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            container.leftStackView.addArrangedSubview(authorAvatarView)
        } else {
            container.centerStackView.backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBackground
            container.rightStackView.addArrangedSubview(authorAvatarView)
        }
    }
}
