//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageUploadResponse: Sendable, Decodable {
    let file: String?
    let thumbUrl: String?
    /// Array of image size configurations
    let uploadSizes: [ImageSize]?

    init(file: String? = nil, thumbUrl: String? = nil, uploadSizes: [ImageSize]? = nil) {
        self.file = file
        self.thumbUrl = thumbUrl
        self.uploadSizes = uploadSizes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        case thumbUrl = "thumb_url"
        case uploadSizes = "upload_sizes"
    }
}
