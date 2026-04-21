//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UploadChannelFileResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// URL to the uploaded asset. Should be used to put to `asset_url` attachment field
    var file: String?
    var moderationAction: String?
    /// URL of the file thumbnail for supported file formats. Should be put to `thumb_url` attachment field
    var thumbUrl: String?

    init(duration: String, file: String? = nil, moderationAction: String? = nil, thumbUrl: String? = nil) {
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

    static func == (lhs: UploadChannelFileResponse, rhs: UploadChannelFileResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.file == rhs.file &&
            lhs.moderationAction == rhs.moderationAction &&
            lhs.thumbUrl == rhs.thumbUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(file)
        hasher.combine(moderationAction)
        hasher.combine(thumbUrl)
    }
}
