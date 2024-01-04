//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRTMPIngress: Codable, Hashable {
    public var address: String
    
    public init(address: String) {
        self.address = address
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case address
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(address, forKey: .address)
    }
}
