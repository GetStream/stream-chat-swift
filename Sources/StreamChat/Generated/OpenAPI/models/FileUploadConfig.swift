//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FileUploadConfig: Sendable, Codable, JSONEncodable {
    let allowedFileExtensions: [String]
    let allowedMimeTypes: [String]
    let blockedFileExtensions: [String]
    let blockedMimeTypes: [String]
    let sizeLimit: Int

    init(allowedFileExtensions: [String], allowedMimeTypes: [String], blockedFileExtensions: [String], blockedMimeTypes: [String], sizeLimit: Int) {
        self.allowedFileExtensions = allowedFileExtensions
        self.allowedMimeTypes = allowedMimeTypes
        self.blockedFileExtensions = blockedFileExtensions
        self.blockedMimeTypes = blockedMimeTypes
        self.sizeLimit = sizeLimit
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case allowedFileExtensions = "allowed_file_extensions"
        case allowedMimeTypes = "allowed_mime_types"
        case blockedFileExtensions = "blocked_file_extensions"
        case blockedMimeTypes = "blocked_mime_types"
        case sizeLimit = "size_limit"
    }
}
