//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FlagRequest: Codable, Hashable {
    public var reason: String? = nil
    public var targetMessageId: String? = nil
    public var custom: [String: RawJSON]? = nil

    public init(reason: String? = nil, targetMessageId: String? = nil, custom: [String: RawJSON]? = nil) {
        self.reason = reason
        self.targetMessageId = targetMessageId
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
        case targetMessageId = "target_message_id"
        case custom
    }
}
