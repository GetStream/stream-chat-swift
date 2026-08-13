//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendMessageResponsePayload: Sendable, Codable, JSONEncodable {
    /// Represents any chat message
    let message: MessagePayload

    init(message: MessagePayload) {
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }
}
