//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// Value to pass to the next search query in order to paginate
    var next: String?
    /// Value that points to the previous page. Pass as the next value in a search query to paginate backwards
    var previous: String?
    /// Search results
    var results: [SearchResult]
    var resultsWarning: SearchWarning?

    init(duration: String, next: String? = nil, previous: String? = nil, results: [SearchResult], resultsWarning: SearchWarning? = nil) {
        self.duration = duration
        self.next = next
        self.previous = previous
        self.results = results
        self.resultsWarning = resultsWarning
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case next
        case previous
        case results
        case resultsWarning = "results_warning"
    }

    static func == (lhs: SearchResponse, rhs: SearchResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.previous == rhs.previous &&
            lhs.results == rhs.results &&
            lhs.resultsWarning == rhs.resultsWarning
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(previous)
        hasher.combine(results)
        hasher.combine(resultsWarning)
    }
}
