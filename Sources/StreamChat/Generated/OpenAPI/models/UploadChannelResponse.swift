//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UploadChannelResponse: Sendable, Decodable {
    let file: String?
    let moderationAction: String?
    let thumbUrl: String?
    /// Array of image size configurations
    let uploadSizes: [ImageSize]?

    init(
        file: String? = nil,
        moderationAction: String? = nil,
        thumbUrl: String? = nil,
        uploadSizes: [ImageSize]? = nil
    ) {
        self.file = file
        self.moderationAction = moderationAction
        self.thumbUrl = thumbUrl
        self.uploadSizes = uploadSizes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        case moderationAction = "moderation_action"
        case thumbUrl = "thumb_url"
        case uploadSizes = "upload_sizes"
    }
}
