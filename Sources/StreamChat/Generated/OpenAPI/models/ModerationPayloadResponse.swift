//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationPayloadResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Custom data for moderation
    var custom: [String: RawJSON]?
    /// Image URLs to moderate
    var images: [String]?
    /// Text content to moderate
    var texts: [String]?
    /// Video URLs to moderate
    var videos: [String]?

    init(custom: [String: RawJSON]? = nil, images: [String]? = nil, texts: [String]? = nil, videos: [String]? = nil) {
        self.custom = custom
        self.images = images
        self.texts = texts
        self.videos = videos
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case images
        case texts
        case videos
    }

    static func == (lhs: ModerationPayloadResponse, rhs: ModerationPayloadResponse) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.images == rhs.images &&
            lhs.texts == rhs.texts &&
            lhs.videos == rhs.videos
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(images)
        hasher.combine(texts)
        hasher.combine(videos)
    }
}
