//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol AttachmentPayloadType: Codable {
    static var type: AttachmentType { get }
}

public struct AttachmentEnvelope {
    public let type: AttachmentType
    public let payload: Encodable?
    public let localFileURL: URL?
}

public extension AttachmentEnvelope {
    init<Payload: AttachmentPayloadType>(payload: Payload) {
        self.init(
            type: Payload.type,
            payload: payload,
            localFileURL: nil
        )
    }

    init?(localFileURL: URL) {
        guard let file = localFileURL.attachmentFile else { return nil }

        let payload: AttachmentPayloadType
        switch file.type {
        case .jpeg, .png:
            payload = AttachmentImagePayload(
                title: localFileURL.lastPathComponent,
                imageURL: localFileURL,
                imagePreviewURL: localFileURL
            )
        default:
            payload = AttachmentFilePayload(
                title: localFileURL.lastPathComponent,
                assetURL: localFileURL,
                file: file
            )
        }

        self.init(
            type: Swift.type(of: payload).type,
            payload: payload,
            localFileURL: localFileURL
        )
    }
}
