//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchAllMessagesSection: Sendable, Decodable {
    let error: SearchAllSectionError?
    /// Opaque cursor for the next page of this section, present only when more results exist. Pass it back under next.messages with the same query
    let next: String?
    /// Matching messages, newest first, in the same shape as the search endpoint's results
    let results: [SearchResult]?
    let warning: SearchAllWarning?

    init(
        error: SearchAllSectionError? = nil,
        next: String? = nil,
        results: [SearchResult]? = nil,
        warning: SearchAllWarning? = nil
    ) {
        self.error = error
        self.next = next
        self.results = results
        self.warning = warning
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.error = try container.decodeIfPresent(SearchAllSectionError.self, forKey: .error)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.results = try container.decodeIfPresent([SearchResult].self, forKey: .results)
        self.warning = try container.decodeIfPresent(SearchAllWarning.self, forKey: .warning)
    }
}
