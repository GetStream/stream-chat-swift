//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GetManyMessagesResponse: Codable, Hashable {
    public var duration: String
    public var messages: [Message]

    public init(duration: String, messages: [Message]) {
        self.duration = duration
        self.messages = messages
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case messages
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(messages, forKey: .messages)
    }
}
