//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

public typealias _LayoutOptionsResolver<ExtraData: ExtraDataTypes> =
    (_ indexPath: IndexPath, _ messages: [_ChatMessage<ExtraData>]) -> ChatMessageLayoutOptions

public func DefaultLayoutOptionsResolver<ExtraData: ExtraDataTypes>(
    minTimeIntervalBetweenMessagesInGroup: Double = 10
) -> _LayoutOptionsResolver<ExtraData> {
    { indexPath, messages in
        let message = messages[indexPath.item]

        let isLastInGroup: Bool = {
            guard indexPath.item > 0 else { return true }
            
            let nextMessage = messages[indexPath.item - 1]

            guard nextMessage.author == message.author else { return true }
            
            let delay = nextMessage.createdAt.timeIntervalSince(message.createdAt)
            
            return delay > minTimeIntervalBetweenMessagesInGroup
        }()
        
        var options: ChatMessageLayoutOptions = []
        
        if message.isSentByCurrentUser {
            options.insert(.flipped)
        }
        if !isLastInGroup {
            options.insert(.continuousBubble)
        }
        if !isLastInGroup && !message.isSentByCurrentUser {
            options.insert(.avatarSizePadding)
        }
        if isLastInGroup {
            options.insert(.metadata)
        }
        if !message.textContent.isEmpty {
            options.insert(.text)
        }
        
        guard message.deletedAt == nil else {
            return options
        }
        
        if isLastInGroup && !message.isSentByCurrentUser {
            options.insert(.avatar)
        }
        if message.quotedMessageId != nil {
            options.insert(.quotedMessage)
        }
        if message.isPartOfThread {
            options.insert(.threadInfo)
            // The bubbles with thread look like continuous bubbles
            options.insert(.continuousBubble)
        }
        if !message.reactionScores.isEmpty {
            options.insert(.reactions)
        }
        if message.lastActionFailed {
            options.insert(.error)
        }

        let attachmentOptions: ChatMessageLayoutOptions = message.attachments.reduce([]) { options, attachment in
            if (attachment as? ChatMessageDefaultAttachment)?.actions.isEmpty == false {
                return options.union(.actions)
            }
            
            switch attachment.type {
            case .image:
                return options.union(.photoPreview)
            case .giphy:
                return options.union(.giphy)
            case .file:
                return options.union(.filePreview)
            case .link:
                return options.union(.linkPreview)
            default:
                return options
            }
        }
        
        if attachmentOptions.contains(.actions) {
            options.insert(.actions)
        } else if attachmentOptions.intersection([.photoPreview, .giphy, .filePreview]).isEmpty == false {
            options.formUnion(attachmentOptions.subtracting(.linkPreview))
        } else if attachmentOptions.contains(.linkPreview) {
            options.insert(.linkPreview)
        }
        
        return options
    }
}
