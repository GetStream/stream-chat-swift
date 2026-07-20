//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class PushPreferencesResponse: Sendable, Codable, JSONEncodable {
    let chatLevel: String?
    let disabledUntil: Date?

    init(
        chatLevel: String? = nil,
        disabledUntil: Date? = nil
    ) {
        self.chatLevel = chatLevel
        self.disabledUntil = disabledUntil
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case chatLevel = "chat_level"
        case disabledUntil = "disabled_until"
    }
}
