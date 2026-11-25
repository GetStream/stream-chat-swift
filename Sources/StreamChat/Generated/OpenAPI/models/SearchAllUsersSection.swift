//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchAllUsersSection: Sendable, Decodable {
    let error: SearchAllSectionError?
    /// Opaque cursor for the next page of this section, present only when more results exist. Pass it back under next.users with the same query
    let next: String?
    /// Users whose name or username starts with the query, in the same shape as the query users endpoint's results
    let users: [FullUserResponse]?
    let warning: SearchAllWarning?

    init(
        error: SearchAllSectionError? = nil,
        next: String? = nil,
        users: [FullUserResponse]? = nil,
        warning: SearchAllWarning? = nil
    ) {
        self.error = error
        self.next = next
        self.users = users
        self.warning = warning
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.error = try container.decodeIfPresent(SearchAllSectionError.self, forKey: .error)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.users = try container.decodeIfPresent([FullUserResponse].self, forKey: .users)
        self.warning = try container.decodeIfPresent(SearchAllWarning.self, forKey: .warning)
    }
}
