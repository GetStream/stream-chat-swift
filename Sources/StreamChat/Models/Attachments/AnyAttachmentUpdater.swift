//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Helper component to update the payload of a type-erased attachment.
public struct AnyAttachmentUpdater {
    public init() {}

    /// Updates the underlying payload of a type-erased attachment.
    /// It does nothing if the payload is not of the specified type.
    /// - Parameters:
    ///   - attachment: The type-erased attachment.
    ///   - payloadType: The type of the payload
    ///   - updates: A closure to change the attachment's payload properties.
    public func update<Payload: AttachmentPayload>(
        _ attachment: inout AnyChatMessageAttachment,
        forPayload payloadType: Payload.Type,
        _ updates: ((inout Payload) -> Void)
    ) {
        do {
            if let attachmentPayload = attachment.attachment(payloadType: payloadType)?.payload {
                var payload = attachmentPayload
                updates(&payload)
                attachment.payload = try JSONEncoder.stream.encode(payload.asAnyEncodable)
            }
        } catch {
            log.error(error.localizedDescription)
        }
    }
}
