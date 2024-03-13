//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MarkUnreadRequest: Codable, Hashable {
    public var messageId: String
    public var threadId: String

    public init(messageId: String, threadId: String) {
        self.messageId = messageId
        self.threadId = threadId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        case threadId = "thread_id"
    }
}
