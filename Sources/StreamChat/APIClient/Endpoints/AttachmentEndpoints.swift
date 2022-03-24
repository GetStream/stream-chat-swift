//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
}
