//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UploadConfig: Sendable, Decodable {
    /// The allowed file extensions.
    public let allowedFileExtensions: [String]
    /// The allowed mime types.
    public let allowedMimeTypes: [String]
    /// The blocked file extensions.
    public let blockedFileExtensions: [String]
    /// The blocked mime types.
    public let blockedMimeTypes: [String]
    /// The file size limit allowed in Bytes. 0 means no app-specific limit.
    /// This value is configurable from Stream's Dashboard App Settings.
    public let sizeLimit: Int

    init(
        allowedFileExtensions: [String],
        allowedMimeTypes: [String],
        blockedFileExtensions: [String],
        blockedMimeTypes: [String],
        sizeLimit: Int
    ) {
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

extension UploadConfig: Hashable {
    public static func == (lhs: UploadConfig, rhs: UploadConfig) -> Bool {
        lhs.allowedFileExtensions == rhs.allowedFileExtensions &&
            lhs.allowedMimeTypes == rhs.allowedMimeTypes &&
            lhs.blockedFileExtensions == rhs.blockedFileExtensions &&
            lhs.blockedMimeTypes == rhs.blockedMimeTypes &&
            lhs.sizeLimit == rhs.sizeLimit
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(allowedFileExtensions)
        hasher.combine(allowedMimeTypes)
        hasher.combine(blockedFileExtensions)
        hasher.combine(blockedMimeTypes)
        hasher.combine(sizeLimit)
    }
}
