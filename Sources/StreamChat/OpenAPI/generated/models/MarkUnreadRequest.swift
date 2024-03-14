//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MarkUnreadRequest: Codable, Hashable {
    public var messageId: String? = nil
    public var threadId: String? = nil

    public init(messageId: String? = nil, threadId: String? = nil) {
        self.messageId = messageId
        self.threadId = threadId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        case threadId = "thread_id"
    }
}
