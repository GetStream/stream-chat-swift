//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateDraftRequest: Sendable, Encodable, JSONEncodable {
    /// Message data for creating or updating a message
    let message: MessageRequest

    init(message: MessageRequest) {
        self.message = message
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(message, forKey: .message)
    }
}
