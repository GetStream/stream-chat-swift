//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThumbnailResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var imageUrl: String

    init(imageUrl: String) {
        self.imageUrl = imageUrl
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case imageUrl = "image_url"
    }

    static func == (lhs: ThumbnailResponse, rhs: ThumbnailResponse) -> Bool {
        lhs.imageUrl == rhs.imageUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(imageUrl)
    }
}
