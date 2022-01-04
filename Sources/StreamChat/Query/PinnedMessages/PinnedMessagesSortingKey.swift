//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describing a value that can be used as a sorting when paginating pinned messages.
public struct PinnedMessagesSortingKey: RawRepresentable, Hashable, SortingKey {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension PinnedMessagesSortingKey {
    /// When provided sorts pinned messages by `pinned_at` field.
    static let pinnedAt = Self(rawValue: MessagePayloadsCodingKeys.pinnedAt.rawValue)
}
