//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MarkReadRequest: Codable, Hashable {
    public var messageId: String? = nil
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(messageId: String? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.messageId = messageId
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        case userId = "user_id"
        case user
    }
}
