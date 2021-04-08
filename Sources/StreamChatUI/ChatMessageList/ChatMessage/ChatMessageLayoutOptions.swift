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

    static let avatar = Self(rawValue: 1 << 1)
    static let metadata = Self(rawValue: 1 << 2)
    static let text = Self(rawValue: 1 << 3)
    static let quotedMessage = Self(rawValue: 1 << 4)
    static let avatarSizePadding = Self(rawValue: 1 << 10)
    
    /// The message bubble appearance
    static let continuousBubble = Self(rawValue: 1 << 5)

    /// Attachments
    static let filePreview = Self(rawValue: 1 << 6)
    static let linkPreview = Self(rawValue: 1 << 7)
    static let photoPreview = Self(rawValue: 1 << 8)
    static let giphy = Self(rawValue: 1 << 9)

    // Bits 28...31 are reserved for your custom options
}
