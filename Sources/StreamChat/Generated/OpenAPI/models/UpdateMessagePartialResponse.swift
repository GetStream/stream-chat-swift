//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class UpdateMessagePartialResponse: Sendable, Decodable {
    /// Represents any chat message
    let message: MessageResponse?

    init(message: MessageResponse? = nil) {
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }
}
