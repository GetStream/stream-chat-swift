//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// User request object
final class UserRequest: Sendable, Encodable, JSONEncodable {
    /// Custom user data
    let custom: [String: RawJSON]?
    /// User ID
    let id: String
    /// User's profile image URL
    let image: String?
    /// Optional name of user
    let name: String?

    init(custom: [String: RawJSON]? = nil, id: String, image: String? = nil, name: String? = nil) {
        self.custom = custom
        self.id = id
        self.image = image
        self.name = name
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(name, forKey: .name)
    }
}
