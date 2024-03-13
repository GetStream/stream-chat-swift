//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageUpdate: Codable, Hashable {
    public var oldText: String? = nil
    public var changeSet: MessageChangeSet? = nil

    public init(oldText: String? = nil, changeSet: MessageChangeSet? = nil) {
        self.oldText = oldText
        self.changeSet = changeSet
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case oldText = "old_text"
        case changeSet = "change_set"
    }
}
