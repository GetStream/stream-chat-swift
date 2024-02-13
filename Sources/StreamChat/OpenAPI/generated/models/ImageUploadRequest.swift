//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ImageUploadRequest: Codable, Hashable {
    public var file: String? = nil
    public var uploadSizes: [ImageSizeRequest]? = nil
    public var user: OnlyUserIDRequest? = nil

    public init(file: String? = nil, uploadSizes: [ImageSizeRequest]? = nil, user: OnlyUserIDRequest? = nil) {
        self.file = file
        self.uploadSizes = uploadSizes
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        case uploadSizes = "upload_sizes"
        case user
    }
}
