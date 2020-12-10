//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func uploadAttachment(with id: AttachmentId, type: AttachmentType) -> Endpoint<FileUploadPayload> {
        .init(
            path: "channels/\(id.cid.type)/\(id.cid.id)/\(type == .image ? "image" : "file")",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
}
