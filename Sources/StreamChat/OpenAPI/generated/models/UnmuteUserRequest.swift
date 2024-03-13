//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UnmuteUserRequest: Codable, Hashable {
    public var targetIds: [String]
    public var timeout: Int? = nil

    public init(targetIds: [String], timeout: Int? = nil) {
        self.targetIds = targetIds
        self.timeout = timeout
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetIds = "target_ids"
        case timeout
    }
}
