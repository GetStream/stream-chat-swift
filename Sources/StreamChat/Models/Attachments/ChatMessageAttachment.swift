//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat message attachment.
/// `ChatMessageAttachment<Payload>` is an immutable snapshot of message attachment at the given time.
@dynamicMemberLookup
public struct ChatMessageAttachment<Payload> {
    /// The attachment identifier.
    public let id: AttachmentId

    /// The attachment type.
    public let type: AttachmentType

    /// The attachment payload.
    public var payload: Payload

    /// The uploading state of the attachment.
    ///
    /// Reflects uploading progress for local attachments that require file uploading.
    /// Is `nil` for local attachments that don't need to be uploaded.
    ///
    /// Becomes `nil` when the message with the current attachment is sent.
    public let uploadingState: AttachmentUploadingState?
}

public extension ChatMessageAttachment {
    subscript<T>(dynamicMember keyPath: KeyPath<Payload, T>) -> T {
        payload[keyPath: keyPath]
    }
}

extension ChatMessageAttachment: Equatable where Payload: Equatable {}
extension ChatMessageAttachment: Hashable where Payload: Hashable {}

/// A type representing the uploading state for attachments that require prior uploading.
public struct AttachmentUploadingState: Hashable {
    /// The local file URL that is being uploaded.
    public let localFileURL: URL

    /// The uploading state.
    public let state: LocalAttachmentState

    /// The information about file size/mimeType.
    public let file: AttachmentFile
}

// MARK: - Type erasure/recovery

public typealias AnyChatMessageAttachment = ChatMessageAttachment<Data>

public extension AnyChatMessageAttachment {
    /// Converts type-erased attachment to the attachment with the concrete payload.
    ///
    /// Attachment with the requested payload type will be returned if the type-erased payload
    /// has a `Payload` instance under the hood OR if it’s a `Data` that can be decoded as a `Payload`.
    ///
    /// - Parameter payloadType: The payload type the current type-erased attachment payload should be treated as.
    /// - Returns: The attachment with the requested payload type or `nil`.
    func attachment<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> ChatMessageAttachment<Payload>? {
        guard
            Payload.type == type || type == .unknown,
            let concretePayload = try? JSONDecoder.stream.decode(Payload.self, from: payload)
        else { return nil }
        
        return .init(
            id: id,
            type: type,
            payload: concretePayload,
            uploadingState: uploadingState
        )
    }
}

// swiftlint:disable force_try
public extension ChatMessageAttachment where Payload: AttachmentPayload {
    /// Returns an attachment matching `self` but payload casted to `Any`.
    var asAnyAttachment: AnyChatMessageAttachment {
        AnyChatMessageAttachment(
            id: id,
            type: type,
            payload: try! JSONEncoder.stream.encode(payload),
            uploadingState: uploadingState
        )
    }
}
