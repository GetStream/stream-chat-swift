//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResult: Sendable, Decodable {
    let message: SearchResultMessage

    init(message: SearchResultMessage) {
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.message = try container.decode(SearchResultMessage.self, forKey: .message)
    }
}
