//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat

public struct AttachmentListViewData<ExtraData: ExtraDataTypes> {
    public let attachments: [_ChatMessageAttachment<ExtraData>]
    public let didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?

    public init(
        attachments: [_ChatMessageAttachment<ExtraData>],
        didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?
    ) {
        self.attachments = attachments
        self.didTapOnAttachment = didTapOnAttachment
    }

    var items: [ItemData] {
        attachments.map { attachment in
            return .init(
                attachment: attachment,
                didTapOnAttachment: {
                    didTapOnAttachment?(attachment)
                }
            )
        }
    }
}

extension AttachmentListViewData {
    public struct ItemData {
        public let attachment: _ChatMessageAttachment<ExtraData>
        public let didTapOnAttachment: () -> Void
    }
}
