//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat message attachment.
/// `_ChatMessageAttachment<Payload>` is an immutable snapshot of message attachment at the given time.
///
/// - Note: `_ChatMessageAttachment` type is not meant to be used directly. For each specific attachment type
/// there is a type alias which resolves the generic (`ChatMessageFileAttachment`, `ChatMessageImageAttachment`, etc.).
/// If you have your own attachment with custom payload consider having a type alias.
@dynamicMemberLookup
public struct _ChatMessageAttachment<Payload> {
    /// The attachment identifier.
    public let id: AttachmentId

    /// The attachment type.
    public let type: AttachmentType

    /// The attachment payload.
    public let payload: Payload

    /// The uploading state of the attachment.
    ///
    /// Reflects uploading progress for local attachments that require file uploading.
    /// Is `nil` for local attachments that don't need to be uploaded.
    ///
    /// Becomes `nil` when the message with the current attachment is sent.
    public let uploadingState: AttachmentUploadingState?
}

public extension _ChatMessageAttachment {
    subscript<T>(dynamicMember keyPath: KeyPath<Payload, T>) -> T {
        payload[keyPath: keyPath]
    }
}

extension _ChatMessageAttachment: Equatable where Payload: Equatable {}

/// A type representing the uploading state for attachments that require prior uploading.
public struct AttachmentUploadingState: Equatable {
    /// The local file URL that is being uploaded.
    public let localFileURL: URL

    /// The uploading state.
    public let state: LocalAttachmentState

    /// The information about file size/mimeType.
    public let file: AttachmentFile
}

// MARK: - Type erasure/recovery

public typealias AnyChatMessageAttachment = _ChatMessageAttachment<Any>

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
    ) -> _ChatMessageAttachment<Payload>? {
        guard Payload.type == type || type == .unknown else { return nil }

        let concretePayload: Payload
        switch payload {
        case let payload as Payload:
            concretePayload = payload
        case let data as Data:
            guard
                let decodedPayload = try? JSONDecoder.stream.decode(Payload.self, from: data)
            else { return nil }

            concretePayload = decodedPayload
        default:
            return nil
        }

        return .init(
            id: id,
            type: type,
            payload: concretePayload,
            uploadingState: uploadingState
        )
    }
}

public extension _ChatMessageAttachment {
    /// Returns an attachment matching `self` but payload casted to `Any`.
    var asAnyAttachment: AnyChatMessageAttachment {
        .init(
            id: id,
            type: type,
            payload: payload as Any,
            uploadingState: uploadingState
        )
    }
}
