//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct FlagRequestBody: Codable, Hashable {
    let reason: String?
    let targetMessageId: String?
    let targetUserId: String?
    let custom: [String: RawJSON]?

    init(reason: String? = nil, targetMessageId: String? = nil, targetUserId: String? = nil, custom: [String: RawJSON]? = nil) {
        self.reason = reason
        self.targetMessageId = targetMessageId
        self.targetUserId = targetUserId
        self.custom = custom
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
        case targetMessageId = "target_message_id"
        case targetUserId = "target_user_id"
        case custom
    }
}
