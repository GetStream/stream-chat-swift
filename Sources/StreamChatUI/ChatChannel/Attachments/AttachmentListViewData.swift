//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat

public struct AttachmentListViewData<ExtraData: ExtraDataTypes> {
    public let attachments: [_ChatMessageAttachment<ExtraData>]
    public let didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?
    public let didTapOnAttachmentAction: ((_ChatMessageAttachment<ExtraData>, AttachmentAction) -> Void)?

    public init(
        attachments: [_ChatMessageAttachment<ExtraData>],
        didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?,
        didTapOnAttachmentAction: ((_ChatMessageAttachment<ExtraData>, AttachmentAction) -> Void)?
    ) {
        self.attachments = attachments
        self.didTapOnAttachment = didTapOnAttachment
        self.didTapOnAttachmentAction = didTapOnAttachmentAction
    }

    var items: [ItemData] {
        attachments.map { attachment in
            return .init(
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

extension AttachmentListViewData {
    public struct ItemData {
        public let attachment: _ChatMessageAttachment<ExtraData>
        public let didTapOnAttachment: () -> Void
        public let didTapOnAttachmentAction: (AttachmentAction) -> Void
    }
}
