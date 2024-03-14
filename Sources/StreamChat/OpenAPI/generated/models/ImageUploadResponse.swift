//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ImageUploadResponse: Codable, Hashable {
    public var duration: String
    public var file: String? = nil
    public var thumbUrl: String? = nil
    public var uploadSizes: [ImageSize]? = nil

    public init(duration: String, file: String? = nil, thumbUrl: String? = nil, uploadSizes: [ImageSize]? = nil) {
        self.duration = duration
        self.file = file
        self.thumbUrl = thumbUrl
        self.uploadSizes = uploadSizes
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case file
        case thumbUrl = "thumb_url"
        case uploadSizes = "upload_sizes"
    }
}