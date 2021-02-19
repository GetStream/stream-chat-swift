//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

internal typealias ChatMessageGroupPart = _ChatMessageGroupPart<NoExtraData>

@dynamicMemberLookup
internal struct _ChatMessageGroupPart<ExtraData: ExtraDataTypes> {
    internal let message: _ChatMessage<ExtraData>
    internal let quotedMessage: _ChatMessage<ExtraData>?
    internal let isLastInGroup: Bool
    internal let didTapOnAttachment: ((ChatMessageDefaultAttachment) -> Void)?
    internal let didTapOnAttachmentAction: ((ChatMessageDefaultAttachment, AttachmentAction) -> Void)?

    internal var isPartOfThread: Bool {
        let isThreadStart = message.replyCount > 0
        let isThreadReplyInChannel = message.showReplyInChannel
        return isThreadStart || isThreadReplyInChannel
    }
}

extension _ChatMessageGroupPart {
    internal subscript<T>(dynamicMember keyPath: KeyPath<_ChatMessage<ExtraData>, T>) -> T {
        message[keyPath: keyPath]
    }
}
