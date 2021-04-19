//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChatMessageLayoutOptions: OptionSet, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension ChatMessageLayoutOptions {
    /// Typically the messages sent by the current user have flipped content
    static let flipped = Self(rawValue: 1 << 0)
    static let maxWidth = Self(rawValue: 1 << 15)

    static let avatar = Self(rawValue: 1 << 1)
    static let metadata = Self(rawValue: 1 << 2)
    static let authorName = Self(rawValue: 1 << 16)
    static let text = Self(rawValue: 1 << 3)
    static let quotedMessage = Self(rawValue: 1 << 4)
    static let avatarSizePadding = Self(rawValue: 1 << 10)
    static let threadInfo = Self(rawValue: 1 << 12)
    static let reactions = Self(rawValue: 1 << 13)
    static let error = Self(rawValue: 1 << 14)

    /// The message bubble appearance
    static let continuousBubble = Self(rawValue: 1 << 5)
}
