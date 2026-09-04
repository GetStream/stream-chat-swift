//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetRepliesResponse: Sendable, Decodable {
    let messages: [MessageResponse]

    init(messages: [MessageResponse]) {
        self.messages = messages
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case messages
    }
}
