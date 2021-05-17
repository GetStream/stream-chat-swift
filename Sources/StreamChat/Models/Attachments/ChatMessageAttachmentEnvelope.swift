//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol AttachmentPayload: Codable {
    static var type: AttachmentType { get }
}

public struct ChatMessageAttachmentEnvelope {
    public let type: AttachmentType
    public let payload: Encodable?
    public let localFileURL: URL?
}

public extension ChatMessageAttachmentEnvelope {
    init<Payload: AttachmentPayload>(payload: Payload) {
        self.init(
            type: Payload.type,
            payload: payload,
            localFileURL: nil
        )
    }

    init(localFileURL: URL) throws {
        let file = try AttachmentFile(url: localFileURL)

        let payload: AttachmentPayload
        switch file.type {
        case .jpeg, .png:
            payload = ImageAttachmentPayload(
                title: localFileURL.lastPathComponent,
                imageURL: localFileURL,
                imagePreviewURL: localFileURL
            )
        default:
            payload = FileAttachmentPayload(
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
