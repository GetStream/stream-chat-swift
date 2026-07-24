//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UploadChannelFileResponse: Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    let duration: String
    /// URL to the uploaded asset. Should be used to put to `asset_url` attachment field
    let file: String?
    let moderationAction: String?
    /// URL of the file thumbnail for supported file formats. Should be put to `thumb_url` attachment field
    let thumbUrl: String?

    init(
        duration: String,
        file: String? = nil,
        moderationAction: String? = nil,
        thumbUrl: String? = nil
    ) {
        self.duration = duration
        self.file = file
        self.moderationAction = moderationAction
        self.thumbUrl = thumbUrl
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case file
        case moderationAction = "moderation_action"
        case thumbUrl = "thumb_url"
    }
}
