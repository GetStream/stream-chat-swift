//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResponse: Sendable, Decodable {
    /// Value to pass to the next search query in order to paginate
    let next: String?
    /// Value that points to the previous page. Pass as the next value in a search query to paginate backwards
    let previous: String?
    /// Search results
    let results: [SearchResult]

    init(next: String? = nil, previous: String? = nil, results: [SearchResult]) {
        self.next = next
        self.previous = previous
        self.results = results
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case next
        case previous
        case results
    }
}
