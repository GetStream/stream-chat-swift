//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserGroup: Identifiable {}

/// A reference to a user group mentioned in a message.
public struct UserGroupMention: Hashable, Identifiable, Sendable {
    /// The group identifier.
    public let id: String

    /// The display name of the group.
    public let name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
