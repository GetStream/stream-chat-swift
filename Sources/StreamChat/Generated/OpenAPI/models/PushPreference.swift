//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class PushPreference: Sendable, Codable, JSONEncodable {
    private let _chatLevel: PushPreferenceLevel?
    public var chatLevel: PushPreferenceLevel { _chatLevel ?? .all }
    public let chatPreferences: ChatPreferences?
    public let disabledUntil: Date?

    init(
        chatLevel: PushPreferenceLevel? = nil,
        chatPreferences: ChatPreferences? = nil,
        disabledUntil: Date? = nil
    ) {
        self._chatLevel = chatLevel
        self.chatPreferences = chatPreferences
        self.disabledUntil = disabledUntil
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case _chatLevel = "chat_level"
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
