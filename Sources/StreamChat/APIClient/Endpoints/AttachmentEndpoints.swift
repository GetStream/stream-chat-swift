//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func uploadAttachment(with cid: ChannelId, type: AttachmentType) -> Endpoint<FileUploadPayload> {
        .init(
            path: .uploadChannelAttachment(channelId: cid.apiPath, type: type == .image ? "image" : "file"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func uploadAttachment(type: AttachmentType) -> Endpoint<FileUploadPayload> {
        .init(
            path: .uploadAttachment(type == .image ? "image" : "file"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteAttachment(url: URL, type: AttachmentType) -> Endpoint<EmptyResponse> {
        .init(
            path: .uploadAttachment(type == .image ? "image" : "file"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["url": url.absoluteString]
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
