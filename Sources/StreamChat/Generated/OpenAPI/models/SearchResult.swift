//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResult: Sendable, Decodable {
    let message: SearchResultMessage

    init(message: SearchResultMessage) {
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }
}
