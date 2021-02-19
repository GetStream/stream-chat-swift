//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

internal typealias ChatMessageAttachmentListViewData = _ChatMessageAttachmentListViewData<NoExtraData>

internal struct _ChatMessageAttachmentListViewData<ExtraData: ExtraDataTypes> {
    internal let attachments: [ChatMessageDefaultAttachment]
    internal let didTapOnAttachment: ((ChatMessageDefaultAttachment) -> Void)?
    internal let didTapOnAttachmentAction: ((ChatMessageDefaultAttachment, AttachmentAction) -> Void)?

    internal init(
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
    internal struct ItemData {
        internal let attachment: ChatMessageDefaultAttachment
        internal let didTapOnAttachment: () -> Void
        internal let didTapOnAttachmentAction: (AttachmentAction) -> Void
    }
}
