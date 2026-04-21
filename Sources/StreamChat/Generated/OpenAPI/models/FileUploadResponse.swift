//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FileUploadResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// URL to the uploaded asset. Should be used to put to `asset_url` attachment field
    var file: String?
    /// URL of the file thumbnail for supported file formats. Should be put to `thumb_url` attachment field
    var thumbUrl: String?

    init(duration: String, file: String? = nil, thumbUrl: String? = nil) {
        self.duration = duration
        self.file = file
        self.thumbUrl = thumbUrl
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case file
        case thumbUrl = "thumb_url"
    }

    static func == (lhs: FileUploadResponse, rhs: FileUploadResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.file == rhs.file &&
            lhs.thumbUrl == rhs.thumbUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(file)
        hasher.combine(thumbUrl)
    }
}
