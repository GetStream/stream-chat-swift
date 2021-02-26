//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type for custom attachment types introduced outside the SDK that will be exposed in `_ChatMessage<ExtraData: ExtraDataTypes>`
/// `data` property contains raw JSON data received from backend.
/// In order to transform this to attachment of your concrete type you should introduce custom attachment type and decode it from
/// `data` using `Decodable` protocol.
public struct ChatMessageRawAttachment: ChatMessageAttachment {
    /// A unique identifier of the attachment.
    public var id: AttachmentId?
    /// Attachment type.
    public let type: AttachmentType
    /// Raw attachment payload data that can be encoded
    public let data: Data?
}
