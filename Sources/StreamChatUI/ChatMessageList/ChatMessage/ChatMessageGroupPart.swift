//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

public typealias ChatMessageGroupPart = _ChatMessageGroupPart<NoExtraData>

@dynamicMemberLookup
public struct _ChatMessageGroupPart<ExtraData: ExtraDataTypes> {
    public let message: _ChatMessage<ExtraData>
    public let quotedMessage: _ChatMessage<ExtraData>?
    /// `true` if `message` is the first one in a group
    public let isFirstInGroup: Bool
    /// `true` if `message` is the last one in a group
    public let isLastInGroup: Bool
    public let didTapOnAttachment: ((ChatMessageDefaultAttachment) -> Void)?
    public let didTapOnAttachmentAction: ((ChatMessageDefaultAttachment, AttachmentAction) -> Void)?
}

public extension _ChatMessage {
    var isPartOfThread: Bool {
        let isThreadStart = replyCount > 0
        let isThreadReplyInChannel = showReplyInChannel
        return isThreadStart || isThreadReplyInChannel
    }
}

extension _ChatMessageGroupPart {
    public subscript<T>(dynamicMember keyPath: KeyPath<_ChatMessage<ExtraData>, T>) -> T {
        message[keyPath: keyPath]
    }
}
