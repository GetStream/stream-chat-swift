//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A single mention suggestion shown in the composer's suggestion list.
///
/// Modeled as a struct wrapping a ``MentionSuggestion/Kind`` value rather
/// than an enum, so new suggestion variants can be added (by the SDK or by
/// customers) without introducing source-breaking changes. Match a suggestion's
/// variant by casting its ``kind`` to one of the built-in kind types.
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

    /// A type that provides the data for a mention suggestion variant.
    ///
    /// The built-in variants are ``MentionSuggestion/User``,
    /// ``MentionSuggestion/Here``, ``MentionSuggestion/Channel``,
    /// ``MentionSuggestion/Role`` and ``MentionSuggestion/Group``.
    /// Conform your own type to provide a custom variant.
    public protocol Kind: Sendable {
        /// A stable identifier for the suggestion (used for diffing in lists).
        var id: String { get }
    }

    /// A user mention suggestion's data.
    public struct User: Kind {
        /// The suggested user.
        public let user: ChatUser

        public var id: String { "user-\(user.id)" }

        public init(user: ChatUser) {
            self.user = user
        }
    }

    /// The `@here` broadcast suggestion's data.
    public struct Here: Kind {
        public var id: String { "broadcast-here" }

        public init() {}
    }

    /// The `@channel` broadcast suggestion's data.
    public struct Channel: Kind {
        public var id: String { "broadcast-channel" }

        public init() {}
    }

    /// A role mention suggestion's data.
    public struct Role: Kind {
        /// The suggested role.
        public let role: StreamChat.Role

        public var id: String { "role-\(role.name)" }

        public init(role: StreamChat.Role) {
            self.role = role
        }
    }

    /// A user group mention suggestion's data.
    public struct Group: Kind {
        /// The suggested user group.
        public let group: UserGroup

        public var id: String { "group-\(group.id)" }

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
