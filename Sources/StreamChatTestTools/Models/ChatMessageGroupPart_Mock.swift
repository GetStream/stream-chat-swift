//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI

public extension ChatMessageGroupPart {
    /// Creates a new `ChatMessageGroupPart` object from the provided data.
    static func mock(
        message: _ChatMessage<ExtraData>,
        quotedMessage: _ChatMessage<ExtraData>? = nil,
        isLastGroup: Bool = false,
        didTapOnAttachment: ((ChatMessageDefaultAttachment) -> Void)? = nil,
        didTapOnAttachmentAction: ((ChatMessageDefaultAttachment, AttachmentAction) -> Void)? = nil
    ) -> Self {
        .init(
            message: message,
            quotedMessage: quotedMessage,
            isLastInGroup: isLastGroup,
            didTapOnAttachment: didTapOnAttachment,
            didTapOnAttachmentAction: didTapOnAttachmentAction
        )
    }
}
