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
}
