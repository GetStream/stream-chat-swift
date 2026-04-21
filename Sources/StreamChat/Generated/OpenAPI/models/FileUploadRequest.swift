//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FileUploadRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// file field
    var file: String?
    var user: OnlyUserID?

    init(file: String? = nil, user: OnlyUserID? = nil) {
        self.file = file
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        case user
    }

    static func == (lhs: FileUploadRequest, rhs: FileUploadRequest) -> Bool {
        lhs.file == rhs.file &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(file)
        hasher.combine(user)
    }
}
