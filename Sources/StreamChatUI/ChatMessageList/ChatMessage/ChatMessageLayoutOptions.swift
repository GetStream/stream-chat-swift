//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias ChatMessageLayoutOptions = Set<ChatMessageLayoutOption>

public extension ChatMessageLayoutOptions {
    var rawValue: String {
        map(\.rawValue).joined(separator: "-")
    }
}

/// Describes the layout of base message content view.
public struct ChatMessageLayoutOption: RawRepresentable, Hashable, Equatable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
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
    static let avatarSizePadding = Self(rawValue: "avatarSizePadding")

    /// If set the message author avatar will be shown.
    static let avatar = Self(rawValue: "avatar")

    /// If set the message timestamp will be shown.
    static let timestamp = Self(rawValue: "timestamp")

    /// If set the message author name will be shown in metadata.
    static let authorName = Self(rawValue: "authorName")

    /// If set the message text content will be shown.
    static let text = Self(rawValue: "text")

    /// If set the message quoted by the current message will be shown.
    static let quotedMessage = Self(rawValue: "quotedMessage")

    /// If set the message thread replies information will be shown.
    static let threadInfo = Self(rawValue: "threadInfo")

    /// If set the error indicator will be shown.
    static let errorIndicator = Self(rawValue: "errorIndicator")

    /// If set the reactions added to the message will be shown.
    static let reactions = Self(rawValue: "reactions")

    /// If set the indicator saying that the message is visible for current user only will be shown.
    static let onlyVisibleForYouIndicator = Self("onlyVisibleForYouIndicator")
    
    /// If set all the content will have centered alignment. By default, the system messages are centered.
    ///
    /// `flipped` and `centered` are mutually exclusive. Only one of these two should be used at a time.
    /// If both are specified in the options, `centered` is prioritized
    static let centered = Self(rawValue: "centered")
}

extension ChatMessageLayoutOption: CustomStringConvertible {
    /// Returns all options the current option set consists of separated by `-` character.
    public var description: String {
        Self.singleOptions
            .compactMap(\.optionName)
            .joined(separator: "-")
    }

    static let singleOptions: [Self] = [
        .flipped,
        .bubble,
        .continuousBubble,
        .avatarSizePadding,
        .avatar,
        .timestamp,
        .authorName,
        .text,
        .quotedMessage,
        .threadInfo,
        .errorIndicator,
        .reactions,
        .onlyVisibleForYouIndicator,
        .centered
    ]

    var optionName: String? {
        rawValue
    }
}
