//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

public typealias ChatMessageAttachmentListViewData = _ChatMessageAttachmentListViewData<NoExtraData>

public struct _ChatMessageAttachmentListViewData<ExtraData: ExtraDataTypes> {
    public let attachments: [ChatMessageDefaultAttachment]
    public let didTapOnAttachment: ((ChatMessageDefaultAttachment) -> Void)?
    public let didTapOnAttachmentAction: ((ChatMessageDefaultAttachment, AttachmentAction) -> Void)?

    public init(
        attachments: [ChatMessageDefaultAttachment],
        didTapOnAttachment: ((ChatMessageDefaultAttachment) -> Void)?,
        didTapOnAttachmentAction: ((ChatMessageDefaultAttachment, AttachmentAction) -> Void)?
    ) {
        self.attachments = attachments
        self.didTapOnAttachment = didTapOnAttachment
        self.didTapOnAttachmentAction = didTapOnAttachmentAction
    }

    var items: [ItemData] {
        attachments.map { attachment in
            .init(
                attachment: attachment,
                didTapOnAttachment: {
                    didTapOnAttachment?(attachment)
                },
                didTapOnAttachmentAction: { action in
                    didTapOnAttachmentAction?(attachment, action)
                }
            )
        }
    }
}

extension _ChatMessageAttachmentListViewData {
    public struct ItemData {
        public let attachment: ChatMessageDefaultAttachment
        public let didTapOnAttachment: () -> Void
        public let didTapOnAttachmentAction: (AttachmentAction) -> Void
    }
}
