//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageUpdate: Sendable, Decodable {
    let changeSet: MessageChangeSet?
    let oldText: String?

    init(changeSet: MessageChangeSet? = nil, oldText: String? = nil) {
        self.changeSet = changeSet
        self.oldText = oldText
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case changeSet = "change_set"
        case oldText = "old_text"
    }
}
