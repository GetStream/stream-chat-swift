//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ReactionResponse: Codable, Hashable {
    public var createdAt: Date
    public var messageId: String
    public var score: Int
    public var type: String
    public var updatedAt: Date
    public var userId: String
    public var custom: [String: RawJSON]
    public var user: UserResponse

    public init(createdAt: Date, messageId: String, score: Int, type: String, updatedAt: Date, userId: String, custom: [String: RawJSON], user: UserResponse) {
        self.createdAt = createdAt
        self.messageId = messageId
        self.score = score
        self.type = type
        self.updatedAt = updatedAt
        self.userId = userId
        self.custom = custom
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case messageId = "message_id"
        case score
        case type
        case updatedAt = "updated_at"
        case userId = "user_id"
        case custom
        case user
    }
}
