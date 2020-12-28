//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat

@dynamicMemberLookup
public struct _ChatMessageGroupPart<ExtraData: ExtraDataTypes> {
    public let message: _ChatMessage<ExtraData>
    public let parentMessageState: ParentMessageState?
    public let isLastInGroup: Bool
    public let didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?
    public let didTapOnAttachmentAction: ((_ChatMessageAttachment<ExtraData>, AttachmentAction) -> Void)?

    public var parentMessage: _ChatMessage<ExtraData>? {
        switch parentMessageState {
        case let .loaded(message):
            return message
        default:
            return nil
        }
    }

    public var isPartOfThread: Bool {
        let isThreadStart = message.replyCount > 0
        let isReplyInChannel = message.parentMessageId != nil && message.showReplyInChannel
        return isThreadStart || isReplyInChannel
    }
}

extension _ChatMessageGroupPart {
    public enum ParentMessageState {
        case loading
        case loaded(_ChatMessage<ExtraData>)
    }
}

extension _ChatMessageGroupPart {
    public subscript<T>(dynamicMember keyPath: KeyPath<_ChatMessage<ExtraData>, T>) -> T {
        message[keyPath: keyPath]
    }
}
