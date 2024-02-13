//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SortParamRequest: Codable, Hashable {
    public var direction: Int? = nil
    public var field: String? = nil

    public init(direction: Int? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        case field
    }
}
