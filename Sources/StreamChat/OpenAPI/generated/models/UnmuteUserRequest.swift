//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UnmuteUserRequest: Codable, Hashable {
    public var timeout: Int? = nil
    public var targetIds: [String]? = nil

    public init(timeout: Int? = nil, targetIds: [String]? = nil) {
        self.timeout = timeout
        self.targetIds = targetIds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case timeout
        case targetIds = "target_ids"
    }
}
