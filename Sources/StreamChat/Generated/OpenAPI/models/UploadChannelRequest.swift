//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UploadChannelRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var file: String?
    /// field with JSON-encoded array of image size configurations
    var uploadSizes: [ImageSize]?
    var user: OnlyUserID?

    init(file: String? = nil, uploadSizes: [ImageSize]? = nil, user: OnlyUserID? = nil) {
        self.file = file
        self.uploadSizes = uploadSizes
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        case uploadSizes = "upload_sizes"
        case user
    }

    static func == (lhs: UploadChannelRequest, rhs: UploadChannelRequest) -> Bool {
        lhs.file == rhs.file &&
            lhs.uploadSizes == rhs.uploadSizes &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(file)
        hasher.combine(uploadSizes)
        hasher.combine(user)
    }
}
