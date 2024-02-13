//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TruncateChannelRequest: Codable, Hashable {
    public var hardDelete: Bool? = nil
    public var skipPush: Bool? = nil
    public var truncatedAt: Date? = nil
    public var message: MessageRequest? = nil

    public init(hardDelete: Bool? = nil, skipPush: Bool? = nil, truncatedAt: Date? = nil, message: MessageRequest? = nil) {
        self.hardDelete = hardDelete
        self.skipPush = skipPush
        self.truncatedAt = truncatedAt
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        case skipPush = "skip_push"
        case truncatedAt = "truncated_at"
        case message
    }
}
