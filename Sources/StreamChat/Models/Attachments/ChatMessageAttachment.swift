//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias AnyChatMessageAttachment = _ChatMessageAttachment<Any>

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

extension _ChatMessageAttachment {
    func attachment<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> _ChatMessageAttachment<Payload>? {
        guard Payload.type == type else { return nil }

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
