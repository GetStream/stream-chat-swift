//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResponse: Sendable, Decodable {
    /// Value to pass to the next search query in order to paginate
    let next: String?
    /// Search results
    let results: [SearchResult]

    init(next: String? = nil, results: [SearchResult]) {
        self.next = next
        self.results = results
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case next
        case results
    }
}
