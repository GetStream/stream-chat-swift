//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func uploadAttachment(with cid: ChannelId, type: AttachmentType) -> Endpoint<FileUploadPayload> {
        .init(
            path: "channels/" + cid.apiPath + "/\(type == .image ? "image" : "file")",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
}
