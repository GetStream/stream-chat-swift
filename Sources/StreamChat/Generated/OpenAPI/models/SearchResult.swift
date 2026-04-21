//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResult: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var message: SearchResultMessage?

    init(message: SearchResultMessage? = nil) {
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.message == rhs.message
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(message)
    }
}
