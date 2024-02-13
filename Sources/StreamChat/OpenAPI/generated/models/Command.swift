//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Command: Codable, Hashable {
    public var args: String
    public var description: String
    public var name: String
    public var set: String
    public var createdAt: Date? = nil
    public var updatedAt: Date? = nil

    public init(args: String, description: String, name: String, set: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.args = args
        self.description = description
        self.name = name
        self.set = set
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case args
        case description
        case name
        case set
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
