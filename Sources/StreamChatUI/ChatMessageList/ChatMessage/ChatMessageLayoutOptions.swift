//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A typealias of `Set<ChatMessageLayoutOption>` to make the API similar of an `OptionSet`.
public typealias ChatMessageLayoutOptions = Set<ChatMessageLayoutOption>

public extension ChatMessageLayoutOptions {
    /// The raw value of all the options that is used to create identify a collection of options.
    /// It is essentially to make the API backwards-compatible with `OptionSet`
    /// and used to create the reuse identifier of the message cell.
    var rawValue: String {
        // Since it is a Set, we need to sort it to make sure the identifier doesn't change.
        map(\.rawValue).sorted().joined(separator: "-")
    }

    mutating func remove(_ options: ChatMessageLayoutOptions) {
        self = subtracting(options)
    }
    
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

    // Probably this is not needed. It will be a breaking change anyway to the current customer
    // since the customer was doing initialising from `ChatMessageLayoutOptions`.
    //
//    @available(*, deprecated, message: "Use the string raw value initialiser.")
//    public init(rawValue: Int) {
//        self.rawValue = "\(rawValue)"
//    }
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

    /// If set the indicator saying that the message is visible for current user only will be shown.
    static let onlyVisibleForYouIndicator: Self = "onlyVisibleForYouIndicator"
    
    /// If set all the content will have centered alignment. By default, the system messages are centered.
    ///
    /// `flipped` and `centered` are mutually exclusive. Only one of these two should be used at a time.
    /// If both are specified in the options, `centered` is prioritized
    static let centered: Self = "centered"
}
