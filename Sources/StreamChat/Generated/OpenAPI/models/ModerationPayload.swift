//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var custom: [String: RawJSON]?
    var images: [String]?
    var texts: [String]?
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

    static func == (lhs: ModerationPayload, rhs: ModerationPayload) -> Bool {
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
