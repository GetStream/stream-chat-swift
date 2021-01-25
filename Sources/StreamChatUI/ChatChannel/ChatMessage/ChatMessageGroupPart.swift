//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

public typealias ChatMessageGroupPart = _ChatMessageGroupPart<NoExtraData>

@dynamicMemberLookup
public struct _ChatMessageGroupPart<ExtraData: ExtraDataTypes> {
    public let message: _ChatMessage<ExtraData>
    public let quotedMessage: _ChatMessage<ExtraData>?
    public let isLastInGroup: Bool
    public let didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?
    public let didTapOnAttachmentAction: ((_ChatMessageAttachment<ExtraData>, AttachmentAction) -> Void)?

    public var isPartOfThread: Bool {
        let isThreadStart = message.replyCount > 0
        let isThreadReplyInChannel = message.showReplyInChannel
        return isThreadStart || isThreadReplyInChannel
    }
}

extension _ChatMessageGroupPart {
    public subscript<T>(dynamicMember keyPath: KeyPath<_ChatMessage<ExtraData>, T>) -> T {
        message[keyPath: keyPath]
    }
}
