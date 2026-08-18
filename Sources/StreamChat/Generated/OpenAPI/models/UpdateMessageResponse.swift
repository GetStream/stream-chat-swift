//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMessageResponse: Sendable, Codable, JSONEncodable {
    /// Represents any chat message
    let message: MessageResponse

    init(message: MessageResponse) {
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }
}
