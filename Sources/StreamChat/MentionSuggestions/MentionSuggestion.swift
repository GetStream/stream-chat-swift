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

    /// The set of mention types provided by the SDK out of the box.
    static let allBuiltIn: Set<MentionType> = [.user, .here, .channel, .role, .group]
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
        .init(UserSuggestion(user: user))
    }

    /// The `@here` broadcast suggestion.
    public static let here = MentionSuggestion(HereSuggestion())

    /// The `@channel` broadcast suggestion.
    public static let channel = MentionSuggestion(ChannelSuggestion())

    /// A role mention suggestion.
    public static func role(_ role: Role) -> MentionSuggestion {
        .init(RoleSuggestion(role: role))
    }

    /// A user group mention suggestion.
    public static func group(_ group: UserGroup) -> MentionSuggestion {
        .init(GroupSuggestion(group: group))
    }

    /// The value describing the suggestion variant.
    public let suggestion: any Suggestion

    /// Wraps the provided suggestion. Use this to provide a custom variant by
    /// passing your own ``MentionSuggestion/Suggestion`` conforming type.
    public init(_ suggestion: any Suggestion) {
        self.suggestion = suggestion
    }

    /// A stable identifier used for diffing the suggestion list.
    public var id: String { suggestion.id }

    /// The type of the suggestion.
    public var type: MentionType { suggestion.mentionType }

    /// The text inserted into the composer when the suggestion is selected.
    ///
    /// The leading `@` that triggered the suggestion stays in place, so this is
    /// the text that follows it (e.g. the user name, role name, etc.).
    public var mentionText: String { suggestion.mentionText }

    /// A type that provides the data for a mention suggestion variant.
    ///
    /// The built-in variants are ``MentionSuggestion/UserSuggestion``,
    /// ``MentionSuggestion/HereSuggestion``, ``MentionSuggestion/ChannelSuggestion``,
    /// ``MentionSuggestion/RoleSuggestion`` and ``MentionSuggestion/GroupSuggestion``.
    /// Conform your own type to provide a custom variant.
    public protocol Suggestion: Sendable {
        /// A stable identifier for the suggestion (used for diffing in lists).
        var id: String { get }
        /// The type of the mention suggestion.
        var mentionType: MentionType { get }
        /// The text inserted into the composer when the suggestion is selected.
        var mentionText: String { get }
    }

    /// A user mention suggestion's data.
    public struct UserSuggestion: Suggestion {
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
    public struct HereSuggestion: Suggestion {
        public var id: String { "broadcast-here" }
        public var mentionType: MentionType { .here }
        public var mentionText: String { "here" }

        public init() {}
    }

    /// The `@channel` broadcast suggestion's data.
    public struct ChannelSuggestion: Suggestion {
        public var id: String { "broadcast-channel" }
        public var mentionType: MentionType { .channel }
        public var mentionText: String { "channel" }

        public init() {}
    }

    /// A role mention suggestion's data.
    public struct RoleSuggestion: Suggestion {
        /// The suggested role.
        public let role: Role

        public var id: String { "role-\(role.name)" }
        public var mentionType: MentionType { .role }
        public var mentionText: String { role.name }

        public init(role: Role) {
            self.role = role
        }
    }

    /// A user group mention suggestion's data.
    public struct GroupSuggestion: Suggestion {
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
