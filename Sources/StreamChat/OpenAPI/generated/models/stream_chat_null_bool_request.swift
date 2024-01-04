//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNullBoolRequest: Codable, Hashable {
    public var hasValue: Bool?
    
    public var value: Bool?
    
    public init(hasValue: Bool?, value: Bool?) {
        self.hasValue = hasValue
        
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hasValue = "HasValue"
        
        case value = "Value"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hasValue, forKey: .hasValue)
        
        try container.encode(value, forKey: .value)
    }
}
