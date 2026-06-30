//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing a user group mention JSON payload (e.g. inside a message).
struct UserGroupMentionPayload: Decodable, Sendable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    func asModel() -> UserGroupMention {
        UserGroupMention(id: id, name: name)
    }
}
