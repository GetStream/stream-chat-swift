//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageUpdate: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var changeSet: MessageChangeSet?
    var oldText: String?

    init(changeSet: MessageChangeSet? = nil, oldText: String? = nil) {
        self.changeSet = changeSet
        self.oldText = oldText
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case changeSet = "change_set"
        case oldText = "old_text"
    }

    static func == (lhs: MessageUpdate, rhs: MessageUpdate) -> Bool {
        lhs.changeSet == rhs.changeSet &&
            lhs.oldText == rhs.oldText
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(changeSet)
        hasher.combine(oldText)
    }
}
