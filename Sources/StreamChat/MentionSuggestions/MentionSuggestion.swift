//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type of a mention that can be suggested in the composer.
///
/// Modeled as a `RawRepresentable` struct rather than an enum so new mention
/// types can be added without introducing source-breaking changes.
public struct MentionType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension MentionType {
    /// A regular user mention (e.g. `@john`).
    static let user: Self = "user"
    /// Notifies the online members of the channel (`@here`).
    static let here: Self = "here"
    /// Notifies everyone in the channel (`@channel`).
    static let channel: Self = "channel"
    /// Mentions all members that have a given role (e.g. `@admin`).
    static let role: Self = "role"
    /// Mentions all members of a user group (e.g. `@Dream Team`).
    static let group: Self = "group"
}

/// A single mention suggestion shown in the composer's suggestion list.
///
/// Modeled as a struct wrapping a ``MentionSuggestion/Content`` value rather
/// than an enum, so new suggestion variants can be added (by the SDK or by
/// customers) without introducing source-breaking changes. Match a suggestion's
/// variant by casting its ``content`` to one of the built-in content types.
public struct MentionSuggestion: Identifiable, Sendable {
    /// A user mention suggestion.
    public static func user(_ user: ChatUser) -> MentionSuggestion {
        .init(User(user: user))
    }

    /// The `@here` broadcast suggestion.
    public static let here = MentionSuggestion(Here())

    /// The `@channel` broadcast suggestion.
    public static let channel = MentionSuggestion(Channel())

    /// A role mention suggestion.
    public static func role(_ role: StreamChat.Role) -> MentionSuggestion {
        .init(Role(role: role))
    }

    /// A user group mention suggestion.
    public static func group(_ group: UserGroup) -> MentionSuggestion {
        .init(Group(group: group))
    }

    /// The value describing the suggestion variant.
    public let kind: any Kind

    /// Wraps the provided suggestion kind. Use this to provide a custom variant
    /// by passing your own ``MentionSuggestion/Kind`` conforming type.
    public init(_ kind: any Kind) {
        self.kind = kind
    }

    /// A stable identifier used for diffing the suggestion list.
    public var id: String { kind.id }

    /// The type of the suggestion.
    public var type: MentionType { kind.mentionType }

    /// The text inserted into the composer when the suggestion is selected.
    ///
    /// The leading `@` that triggered the suggestion stays in place, so this is
    /// the text that follows it (e.g. the user name, role name, etc.).
    public var mentionText: String { kind.mentionText }

    /// A type that provides the data for a mention suggestion variant.
    ///
    /// The built-in variants are ``MentionSuggestion/User``,
    /// ``MentionSuggestion/Here``, ``MentionSuggestion/Channel``,
    /// ``MentionSuggestion/Role`` and ``MentionSuggestion/Group``.
    /// Conform your own type to provide a custom variant.
    public protocol Kind: Sendable {
        /// A stable identifier for the suggestion (used for diffing in lists).
        var id: String { get }
        /// The type of the mention suggestion.
        var mentionType: MentionType { get }
        /// The text inserted into the composer when the suggestion is selected.
        var mentionText: String { get }
    }

    /// A user mention suggestion's data.
    public struct User: Kind {
        /// The suggested user.
        public let user: ChatUser

        public var id: String { "user-\(user.id)" }
        public var mentionType: MentionType { .user }
        public var mentionText: String { user.mentionText }

        public init(user: ChatUser) {
            self.user = user
        }
    }

    /// The `@here` broadcast suggestion's data.
    public struct Here: Kind {
        public var id: String { "broadcast-here" }
        public var mentionType: MentionType { .here }
        public var mentionText: String { "here" }

        public init() {}
    }

    /// The `@channel` broadcast suggestion's data.
    public struct Channel: Kind {
        public var id: String { "broadcast-channel" }
        public var mentionType: MentionType { .channel }
        public var mentionText: String { "channel" }

        public init() {}
    }

    /// A role mention suggestion's data.
    public struct Role: Kind {
        /// The suggested role.
        public let role: StreamChat.Role

        public var id: String { "role-\(role.name)" }
        public var mentionType: MentionType { .role }
        public var mentionText: String { role.name }

        public init(role: StreamChat.Role) {
            self.role = role
        }
    }

    /// A user group mention suggestion's data.
    public struct Group: Kind {
        /// The suggested user group.
        public let group: UserGroup

        public var id: String { "group-\(group.id)" }
        public var mentionType: MentionType { .group }
        public var mentionText: String { group.name }

        public init(group: UserGroup) {
            self.group = group
        }
    }
}

public extension ChatUser {
    /// The text used to represent the user in a mention.
    ///
    /// Returns the user's name when available, falling back to the user's id.
    var mentionText: String {
        if let name, !name.isEmpty {
            return name
        }
        return id
    }
}
