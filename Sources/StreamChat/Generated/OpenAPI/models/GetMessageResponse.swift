//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetMessageResponse: Sendable, Decodable {
    /// Represents any chat message
    let message: MessageWithChannelResponse

    init(message: MessageWithChannelResponse) {
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }
}
