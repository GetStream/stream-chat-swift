//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The enhanced mention suggestions provider.
///
/// In addition to user mentions, it suggests `@here`, `@channel`, roles and user groups.
/// Which of these types is suggested is determined by the channel's own
/// capabilities (`notify-here`, `notify-channel`, `notify-role`, `notify-group`).
///
/// When the channel has more members than are available in
/// `ChatChannel.lastActiveMembers`, members are searched remotely via
/// ``MemberList``.
public final class EnhancedMentionSuggestionsProvider: MentionSuggestionsProvider, Sendable {
    /// When `true`, user suggestions are searched across all app users instead
    /// of only the channel's members and watchers.
    public let mentionAllAppUsers: Bool

    private let userSearch: UserSearch
    private let roleSearch: RoleSearch
    private let userGroupSearch: UserGroupSearch
    private let makeMemberList: @Sendable (ChannelMemberListQuery) -> MemberList
    private let currentUserId: @Sendable () -> UserId?

    /// Creates a new enhanced mention suggestions provider.
    ///
    /// - Parameters:
    ///   - client: The chat client used to perform searches.
    ///   - mentionAllAppUsers: Whether user suggestions are searched across all app users.
    public init(client: ChatClient, mentionAllAppUsers: Bool = false) {
        self.mentionAllAppUsers = mentionAllAppUsers
        userSearch = client.makeUserSearch()
        roleSearch = client.makeRoleSearch()
        userGroupSearch = client.makeUserGroupSearch()
        makeMemberList = { client.makeMemberList(with: $0) }
        currentUserId = { [weak client] in client?.currentUserId }
    }

    public func mentionSuggestions(for request: MentionSuggestionsRequest) async throws -> [MentionSuggestion] {
        let text = request.text
        let channel = request.channel

        // Broadcasts (`@here`, `@channel`) are shown on a bare `@` and filtered
        // by prefix as the user keeps typing.
        var suggestions = broadcastSuggestions(for: text, channel: channel)

        // Roles and groups require a non-empty query to avoid surfacing the
        // entire list on a bare `@`.
        async let roles = (channel.canNotifyRole && !text.isEmpty)
            ? fetchRoles(for: text)
            : []
        async let groups = (channel.canNotifyGroup && !text.isEmpty)
            ? fetchGroups(for: text)
            : []
        async let users = fetchUsers(for: request)

        suggestions += await roles
        suggestions += await groups
        suggestions += await users
        return suggestions
    }

    // MARK: - Private

    private func broadcastSuggestions(
        for text: String,
        channel: ChatChannel
    ) -> [MentionSuggestion] {
        let query = text.lowercased()
        var result: [MentionSuggestion] = []
        if channel.canNotifyChannel, matchesBroadcast("channel", query: query) {
            result.append(.channel)
        }
        if channel.canNotifyHere, matchesBroadcast("here", query: query) {
            result.append(.here)
        }
        return result
    }

    private func matchesBroadcast(_ keyword: String, query: String) -> Bool {
        query.isEmpty || keyword.hasPrefix(query)
    }

    private func fetchRoles(for text: String) async -> [MentionSuggestion] {
        do {
            let roles = try await roleSearch.search(text: text)
            return roles.map { MentionSuggestion.role($0) }
        } catch {
            log.error("Failed to fetch role suggestions: \(error)")
            return []
        }
    }

    private func fetchGroups(for text: String) async -> [MentionSuggestion] {
        do {
            let groups = try await userGroupSearch.search(text: text)
            return groups.map { MentionSuggestion.group($0) }
        } catch {
            log.error("Failed to fetch group suggestions: \(error)")
            return []
        }
    }

    private func fetchUsers(for request: MentionSuggestionsRequest) async -> [MentionSuggestion] {
        do {
            let users = try await MentionSuggestionsSearch.fetchUsers(
                for: request,
                mentionAllAppUsers: mentionAllAppUsers,
                currentUserId: currentUserId(),
                userSearch: userSearch,
                makeMemberList: makeMemberList
            )
            return users.map { MentionSuggestion.user($0) }
        } catch {
            log.error("Failed to fetch user suggestions: \(error)")
            return []
        }
    }
}
