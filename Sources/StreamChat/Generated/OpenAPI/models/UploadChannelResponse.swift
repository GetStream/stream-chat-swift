//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UploadChannelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var file: String?
    var moderationAction: String?
    var thumbUrl: String?
    /// [RawJSON] of image size configurations
    var uploadSizes: [ImageSize]?

    init(duration: String, file: String? = nil, moderationAction: String? = nil, thumbUrl: String? = nil, uploadSizes: [ImageSize]? = nil) {
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

    static func == (lhs: UploadChannelResponse, rhs: UploadChannelResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.file == rhs.file &&
            lhs.moderationAction == rhs.moderationAction &&
            lhs.thumbUrl == rhs.thumbUrl &&
            lhs.uploadSizes == rhs.uploadSizes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(file)
        hasher.combine(moderationAction)
        hasher.combine(thumbUrl)
        hasher.combine(uploadSizes)
    }
}
