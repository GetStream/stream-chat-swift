//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func deleteFile(cid: ChannelId, url: String) -> Endpoint<EmptyResponse> {
        .init(
            path: .deleteFile(cid.apiPath),
            method: .delete,
            queryItems: ["url": url],
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteImage(cid: ChannelId, url: String) -> Endpoint<EmptyResponse> {
        .init(
            path: .deleteImage(cid.apiPath),
            method: .delete,
            queryItems: ["url": url],
            requiresConnectionId: false,
            body: nil
        )
    }
}
