//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The default mention suggestions provider.
///
/// Suggests users only, preserving the historical mention behaviour. By default
/// it searches the channel's members and watchers; pass `mentionAllAppUsers: true`
/// at initialization to search across all app users instead.
public final class DefaultMentionSuggestionsProvider: MentionSuggestionsProvider, Sendable {
    /// When `true`, user suggestions are searched across all app users instead
    /// of only the channel's members and watchers.
    public let mentionAllAppUsers: Bool

    private let userSearch: UserSearch
    private let currentUserId: @Sendable () -> UserId?

    /// Creates a new default mention suggestions provider.
    ///
    /// - Parameters:
    ///   - client: The chat client used to perform user searches.
    ///   - mentionAllAppUsers: Whether user suggestions are searched across all app users.
    public init(client: ChatClient, mentionAllAppUsers: Bool = false) {
        self.mentionAllAppUsers = mentionAllAppUsers
        userSearch = client.makeUserSearch()
        currentUserId = { [weak client] in client?.currentUserId }
    }

    public func mentionSuggestions(for request: MentionSuggestionsRequest) async throws -> [MentionSuggestion] {
        let users: [ChatUser]
        if mentionAllAppUsers {
            let query = MentionSuggestionsSearch.allAppUsersQuery(for: request.text)
            users = try await userSearch.search(query: query)
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
