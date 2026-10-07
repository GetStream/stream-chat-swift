//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageUploadResponse: Sendable, Decodable {
    let file: String?
    let thumbUrl: String?

    init(file: String? = nil, thumbUrl: String? = nil) {
        self.file = file
        self.thumbUrl = thumbUrl
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        case thumbUrl = "thumb_url"
    }
}
