//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ReactionRequest: Codable, Hashable {
    public var type: String
    public var createdAt: Date? = nil
    public var score: Int? = nil
    public var updatedAt: Date? = nil
    public var custom: [String: RawJSON]? = nil

    public init(type: String, createdAt: Date? = nil, score: Int? = nil, updatedAt: Date? = nil, custom: [String: RawJSON]? = nil) {
        self.type = type
        self.createdAt = createdAt
        self.score = score
        self.updatedAt = updatedAt
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case createdAt = "created_at"
        case score
        case updatedAt = "updated_at"
        case custom
    }
}
