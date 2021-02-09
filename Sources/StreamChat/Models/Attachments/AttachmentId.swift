//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object that uniquely identifies a message attachment.
public struct AttachmentId: Hashable {
    /// The cid of the channel the attachment belongs to.
    public let cid: ChannelId

    /// The id of the message the attachments belongs to.
    public let messageId: MessageId

    /// The position of the attachment within the message. The first attachment index is 0, then 1, etc.
    public let index: Int

    public init(
        cid: ChannelId,
        messageId: MessageId,
        index: Int
    ) {
        self.cid = cid
        self.messageId = messageId
        self.index = index
    }
}

// MARK: - RawRepresentable

extension AttachmentId: RawRepresentable {
    static let separator: String = "/"
    
    public init?(rawValue: String) {
        let components = rawValue.components(separatedBy: Self.separator)
        guard
            components.count == 3,
            let cid = try? ChannelId(cid: String(components[0])),
            let index = Int(components[2])
        else { return nil }

        self.init(
            cid: cid,
            messageId: components[1],
            index: index
        )
    }

    public var rawValue: String {
        [cid.rawValue, messageId, String(index)].joined(separator: Self.separator)
    }
}
