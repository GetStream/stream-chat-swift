//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Shared helpers used by the built-in mention suggestion providers.
enum MentionSuggestionsSearch {
    /// Performs an autocomplete search over a list of users.
    ///
    /// Returns users whose `id` or `name` contain the search string, sorted by
    /// their edit distance from the searched string (levenshtein). Both the
    /// search and name strings are normalized (lowercased and with diacritics
    /// removed).
    static func searchUsers(
        _ users: [ChatUser],
        by searchInput: String,
        excludingId: String? = nil
    ) -> [ChatUser] {
        let normalize: (String) -> String = {
            $0.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        }

        let searchInput = normalize(searchInput)

        let matchingUsers = users.filter { $0.id != excludingId }
            .filter { searchInput.isEmpty || $0.id.contains(searchInput) || (normalize($0.name ?? "").contains(searchInput)) }

        let distance: (ChatUser) -> Int = {
            min($0.id.levenshtein(searchInput), $0.name?.levenshtein(searchInput) ?? 1000)
        }

        return Array(Set(matchingUsers)).sorted {
            // A tie breaker is needed here to avoid results from flickering.
            let dist = distance($0) - distance($1)
            if dist == 0 {
                return $0.id < $1.id
            }
            return dist < 0
        }
    }

    /// Builds the query used to search all app users for mention suggestions.
    static func allAppUsersQuery(for searchInput: String) -> UserListQuery {
        UserListQuery(
            filter: .or([
                .autocomplete(.name, text: searchInput),
                .autocomplete(.id, text: searchInput)
            ]),
            sort: [.init(key: .name, isAscending: true)]
        )
    }

    /// Builds the query used to search channel members for mention suggestions.
    static func channelMembersQuery(cid: ChannelId, for searchInput: String) -> ChannelMemberListQuery {
        ChannelMemberListQuery(
            cid: cid,
            filter: .autocomplete(.name, text: searchInput),
            sort: [.init(key: .name, isAscending: true)]
        )
    }

    /// Whether mention suggestions should query members from the backend.
    ///
    /// `ChatChannel.lastActiveMembers` is capped (default 100), so larger channels
    /// need a remote member search.
    static func requiresRemoteMemberSearch(for channel: ChatChannel) -> Bool {
        channel.memberCount > channel.lastActiveMembers.count
    }

    /// Resolves user mention suggestions for the given request.
    ///
    /// Search strategy, in order:
    /// 1. All app users, when `mentionAllAppUsers` is `true`.
    /// 2. Remote channel member search via ``MemberSearch``, when the channel has
    ///    more members than are available in `lastActiveMembers`.
    /// 3. Local search over `lastActiveMembers` and `lastActiveWatchers`.
    static func fetchUsers(
        for request: MentionSuggestionsRequest,
        mentionAllAppUsers: Bool,
        currentUserId: UserId?,
        userSearch: UserSearch,
        memberSearch: MemberSearch
    ) async throws -> [ChatUser] {
        if mentionAllAppUsers {
            let query = allAppUsersQuery(for: request.text)
            return try await userSearch.search(query: query)
        }

        let channel = request.channel
        if requiresRemoteMemberSearch(for: channel) {
            // Empty `@` should not load every member of a large channel.
            guard !request.text.isEmpty else { return [] }

            let query = channelMembersQuery(cid: channel.cid, for: request.text)
            let members = try await memberSearch.search(query: query)
            return members.filter { $0.id != currentUserId }
        }

        return searchUsers(
            channel.lastActiveWatchers.map(\.self) + channel.lastActiveMembers.map(\.self),
            by: request.text,
            excludingId: currentUserId
        )
    }
}
