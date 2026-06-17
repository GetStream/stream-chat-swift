//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The enhanced mention suggestions provider.
///
/// In addition to user mentions, it suggests `@here` and `@channel` broadcasts,
/// roles and user groups, matching the behaviour of the other Stream Chat SDKs.
/// The set of suggested types is controlled by ``MentionSuggestionsConfig/allowedMentionTypes``.
public final class EnhancedMentionSuggestionsProvider: MentionSuggestionsProvider, @unchecked Sendable {
    /// The configuration controlling which mention types are suggested.
    public var config: MentionSuggestionsConfig

    private let userSearch: UserSearch
    private let roleSearch: RoleSearch
    private let userGroupSearch: UserGroupSearch
    private let currentUserId: () -> UserId?

    /// Creates a new enhanced mention suggestions provider.
    ///
    /// - Parameters:
    ///   - client: The chat client used to perform searches.
    ///   - config: The configuration controlling which mention types are suggested.
    public init(client: ChatClient, config: MentionSuggestionsConfig = .enhanced) {
        self.config = config
        userSearch = client.makeUserSearch()
        roleSearch = client.makeRoleSearch()
        userGroupSearch = client.makeUserGroupSearch()
        currentUserId = { [weak client] in client?.currentUserId }
    }

    public func mentionSuggestions(for request: MentionSuggestionsRequest) async throws -> [MentionSuggestion] {
        let text = request.text
        let allowedTypes = config.allowedMentionTypes

        // Broadcasts (`@here`, `@channel`) are shown on a bare `@` and filtered
        // by prefix as the user keeps typing, matching the other SDKs.
        var suggestions = broadcastSuggestions(for: text, allowedTypes: allowedTypes)

        // Roles and groups require a non-empty query to avoid surfacing the
        // entire list on a bare `@`.
        async let roles = (allowedTypes.contains(.role) && !text.isEmpty)
            ? fetchRoles(for: text)
            : []
        async let groups = (allowedTypes.contains(.group) && !text.isEmpty)
            ? fetchGroups(for: text)
            : []
        async let users = allowedTypes.contains(.user)
            ? fetchUsers(for: request)
            : []

        suggestions += await roles
        suggestions += await groups
        suggestions += await users
        return suggestions
    }

    // MARK: - Private

    private func broadcastSuggestions(
        for text: String,
        allowedTypes: Set<MentionType>
    ) -> [MentionSuggestion] {
        let query = text.lowercased()
        var result: [MentionSuggestion] = []
        if allowedTypes.contains(.channel), matchesBroadcast("channel", query: query) {
            result.append(.channel)
        }
        if allowedTypes.contains(.here), matchesBroadcast("here", query: query) {
            result.append(.here)
        }
        return result
    }

    private func matchesBroadcast(_ keyword: String, query: String) -> Bool {
        query.isEmpty || keyword.hasPrefix(query)
    }

    private func fetchRoles(for text: String) async -> [MentionSuggestion] {
        let roles = (try? await roleSearch.search(text: text)) ?? []
        return roles.map { MentionSuggestion.role($0) }
    }

    private func fetchGroups(for text: String) async -> [MentionSuggestion] {
        let groups = (try? await userGroupSearch.search(text: text)) ?? []
        return groups.map { MentionSuggestion.group($0) }
    }

    private func fetchUsers(for request: MentionSuggestionsRequest) async -> [MentionSuggestion] {
        let users: [ChatUser]
        if config.mentionAllAppUsers {
            let query = MentionSuggestionsSearch.allAppUsersQuery(for: request.text)
            users = (try? await userSearch.search(query: query)) ?? []
        } else {
            let channel = request.channel
            users = MentionSuggestionsSearch.searchUsers(
                channel.lastActiveWatchers.map(\.self) + channel.lastActiveMembers.map(\.self),
                by: request.text,
                excludingId: currentUserId()
            )
        }
        return users.map { MentionSuggestion.user($0) }
    }
}
