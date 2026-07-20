//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class PushPreferencesResponse: Sendable, Codable, JSONEncodable {
    let chatLevel: String?
    let chatPreferences: ChatPreferences?
    let disabledUntil: Date?

    init(
        chatLevel: String? = nil,
        chatPreferences: ChatPreferences? = nil,
        disabledUntil: Date? = nil
    ) {
        self.chatLevel = chatLevel
        self.chatPreferences = chatPreferences
        self.disabledUntil = disabledUntil
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case chatLevel = "chat_level"
        case chatPreferences = "chat_preferences"
        case disabledUntil = "disabled_until"
    }
}
