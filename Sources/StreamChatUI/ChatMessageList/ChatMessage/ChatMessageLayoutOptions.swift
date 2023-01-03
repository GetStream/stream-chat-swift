//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A typealias of `Set<ChatMessageLayoutOption>` to make the API similar of an `OptionSet`.
public typealias ChatMessageLayoutOptions = Set<ChatMessageLayoutOption>

extension ChatMessageLayoutOptions: Identifiable {
    /// The id is composed by the raw values of each option joined by "-".
    /// This id is then used to compute the reuse identifier of each message cell.
    public var id: String {
        // Since it is a Set, we need to sort it to make sure the value doesn't change per call.
        map(\.rawValue).sorted().joined(separator: "-")
    }
}

public extension ChatMessageLayoutOptions {
    /// Remove multiple message layout options.
    mutating func remove(_ options: ChatMessageLayoutOptions) {
        self = subtracting(options)
    }

    /// Insert multiple message layout options.
    mutating func insert(_ options: ChatMessageLayoutOptions) {
        options.forEach { self.insert($0) }
    }
}

/// Each message layout option is used to define which views will be part of the message cell.
/// A different combination of layout options will produce a different cell reuse identifier.
public struct ChatMessageLayoutOption: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension ChatMessageLayoutOption {
    /// If set all the content will have trailing alignment. By default, the message sent by the current user is flipped.
    static let flipped: Self = "flipped"

    /// If set the message content will be wrapped into a bubble.
    static let bubble: Self = "bubble"

    /// If set the message bubble will not have a `tail` (rendered by default as a non rounded corner)
    static let continuousBubble: Self = "continuousBubble"

    /// If set the message content will have an offset (from the `trailing` edge if `flipped` is set otherwise from `leading`)
    /// equal to the avatar size.
    static let avatarSizePadding: Self = "avatarSizePadding"

    /// If set the message author avatar will be shown.
    static let avatar: Self = "avatar"

    /// If set the message timestamp will be shown.
    static let timestamp: Self = "timestamp"

    /// If set the message author name will be shown in metadata.
    static let authorName: Self = "authorName"

    /// If set the message text content will be shown.
    static let text: Self = "text"

    /// If set the message quoted by the current message will be shown.
    static let quotedMessage: Self = "quotedMessage"

    /// If set the message thread replies information will be shown.
    static let threadInfo: Self = "threadInfo"

    /// If set the error indicator will be shown.
    static let errorIndicator: Self = "errorIndicator"

    /// If set the reactions added to the message will be shown.
    static let reactions: Self = "reactions"

    /// If set, the indicator saying that the message is visible to the current user only will be shown.
    static let onlyVisibleToYouIndicator: Self = "onlyVisibleToYouIndicator"

    /// If set the delivery status will be shown for the message.
    static let deliveryStatusIndicator: Self = "deliveryStatusIndicator"

    /// If set all the content will have centered alignment. By default, the system messages are centered.
    ///
    /// `flipped` and `centered` are mutually exclusive. Only one of these two should be used at a time.
    /// If both are specified in the options, `centered` is prioritized
    static let centered: Self = "centered"
}

public extension ChatMessageLayoutOption {
    @available(*, deprecated, renamed: "onlyVisibleToYouIndicator")
    static let onlyVisibleForYouIndicator: Self = onlyVisibleToYouIndicator
}
