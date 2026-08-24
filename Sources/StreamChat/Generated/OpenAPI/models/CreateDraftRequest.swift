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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }
}
