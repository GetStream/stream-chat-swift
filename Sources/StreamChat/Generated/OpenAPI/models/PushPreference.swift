//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class PushPreference: Sendable, Codable, JSONEncodable {
    public let chatLevel: String?
    public let chatPreferences: ChatPreferences?
    public let disabledUntil: Date?

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

extension PushPreference: Hashable {
    public static func == (
        lhs: PushPreference,
        rhs: PushPreference
    ) -> Bool {
        lhs.chatLevel == rhs.chatLevel &&
            lhs.chatPreferences == rhs.chatPreferences &&
            lhs.disabledUntil == rhs.disabledUntil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(chatLevel)
        hasher.combine(chatPreferences)
        hasher.combine(disabledUntil)
    }
}
