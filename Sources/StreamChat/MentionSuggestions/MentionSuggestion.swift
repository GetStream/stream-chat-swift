//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The different kinds of mentions that can be suggested in the composer.
public enum MentionType: String, CaseIterable, Sendable {
    /// A regular user mention (e.g. `@john`).
    case user
    /// Notifies the online members of the channel (`@here`).
    case here
    /// Notifies everyone in the channel (`@channel`).
    case channel
    /// Mentions all members that have a given role (e.g. `@admin`).
    case role
    /// Mentions all members of a user group (e.g. `@Dream Team`).
    case group
}

/// A single mention suggestion shown in the composer's suggestion list.
public enum MentionSuggestion: Identifiable, Sendable {
    /// A user suggestion.
    case user(ChatUser)
    /// The `@here` broadcast suggestion.
    case here
    /// The `@channel` broadcast suggestion.
    case channel
    /// A role suggestion.
    case role(Role)
    /// A user group suggestion.
    case group(UserGroup)

    public var id: String {
        switch self {
        case let .user(user):
            return "user-\(user.id)"
        case .here:
            return "broadcast-here"
        case .channel:
            return "broadcast-channel"
        case let .role(role):
            return "role-\(role.name)"
        case let .group(group):
            return "group-\(group.id)"
        }
    }

    /// The type of the suggestion.
    public var type: MentionType {
        switch self {
        case .user: return .user
        case .here: return .here
        case .channel: return .channel
        case .role: return .role
        case .group: return .group
        }
    }

    /// The text inserted into the composer when the suggestion is selected.
    ///
    /// The leading `@` that triggered the suggestion stays in place, so this is
    /// the text that follows it (e.g. the user name, role name, etc.).
    public var mentionText: String {
        switch self {
        case let .user(user):
            return user.mentionText
        case .here:
            return "here"
        case .channel:
            return "channel"
        case let .role(role):
            return role.name
        case let .group(group):
            return group.name
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
