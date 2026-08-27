//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class UploadChannelResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    let duration: String
    let file: String?
    let moderationAction: String?
    let thumbUrl: String?
    /// Array of image size configurations
    let uploadSizes: [ImageSize]?

    init(
        duration: String,
        file: String? = nil,
        moderationAction: String? = nil,
        thumbUrl: String? = nil,
        uploadSizes: [ImageSize]? = nil
    ) {
        self.duration = duration
        self.file = file
        self.moderationAction = moderationAction
        self.thumbUrl = thumbUrl
        self.uploadSizes = uploadSizes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case file
        case moderationAction = "moderation_action"
        case thumbUrl = "thumb_url"
        case uploadSizes = "upload_sizes"
    }
}
