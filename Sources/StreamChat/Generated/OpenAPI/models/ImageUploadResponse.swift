//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageUploadResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    let duration: String
    let file: String?
    let thumbUrl: String?
    /// Array of image size configurations
    let uploadSizes: [ImageSize]?

    init(
        duration: String,
        file: String? = nil,
        thumbUrl: String? = nil,
        uploadSizes: [ImageSize]? = nil
    ) {
        self.duration = duration
        self.file = file
        self.thumbUrl = thumbUrl
        self.uploadSizes = uploadSizes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case file
        case thumbUrl = "thumb_url"
        case uploadSizes = "upload_sizes"
    }
}
