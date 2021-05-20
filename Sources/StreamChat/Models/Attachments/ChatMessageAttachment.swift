//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct AttachmentUploadingState: Equatable {
    public let localFileURL: URL
    public let state: LocalAttachmentState
    public let file: AttachmentFile
}

@dynamicMemberLookup
public struct _ChatMessageAttachment<Payload> {
    public let id: AttachmentId
    public let type: AttachmentType
    public let payload: Payload
    public let uploadingState: AttachmentUploadingState?

    public subscript<T>(dynamicMember keyPath: KeyPath<Payload, T>) -> T {
        payload[keyPath: keyPath]
    }
}

extension _ChatMessageAttachment: Equatable where Payload: Equatable {}

// MARK: - Type erasure/recovery

public typealias AnyChatMessageAttachment = _ChatMessageAttachment<Any>

/// Converts type-erased attachment to the attachment with the concrete payload.
///
/// Attachment with the requested payload type will be returned if the type-erased payload
/// has a `Payload` instance under the hood OR if it’s a `Data` that can be decoded as a `Payload`.
///
/// - Parameter payloadType: The payload type the current type-erased attachment payload should be treated as.
/// - Returns: The attachment with the requested payload type or `nil`.
public extension AnyChatMessageAttachment {
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

extension _ChatMessageAttachment {
    var asAnyAttachment: AnyChatMessageAttachment {
        .init(
            id: id,
            type: type,
            payload: payload as Any,
            uploadingState: uploadingState
        )
    }
}
