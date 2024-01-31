//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func uploadAttachment(with cid: ChannelId, type: AttachmentType) -> Endpoint<FileUploadPayload> {
        .init(
            path: .uploadAttachment(channelId: cid.apiPath, type: type == .image ? "image" : "file"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func enrichUrl(url: URL)
        -> Endpoint<LinkAttachmentPayload> {
        .init(
            path: .og,
            method: .get,
            queryItems: [
                "url": url.absoluteString
            ],
            requiresConnectionId: false,
            body: nil
        )
    }
}
