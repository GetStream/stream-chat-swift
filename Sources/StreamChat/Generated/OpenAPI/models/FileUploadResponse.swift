//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FileUploadResponse: Sendable, Decodable {
    /// URL to the uploaded asset. Should be used to put to `asset_url` attachment field
    let file: String?
    /// URL of the file thumbnail for supported file formats. Should be put to `thumb_url` attachment field
    let thumbUrl: String?

    init(file: String? = nil, thumbUrl: String? = nil) {
        self.file = file
        self.thumbUrl = thumbUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.file = try container.decodeIfPresent(String.self, forKey: .file)
        self.thumbUrl = try container.decodeIfPresent(String.self, forKey: .thumbUrl)
    }
}
