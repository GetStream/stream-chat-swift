//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct HuaweiConfigFields: Codable, Hashable {
    public var enabled: Bool
    public var id: String? = nil
    public var secret: String? = nil

    public init(enabled: Bool, id: String? = nil, secret: String? = nil) {
        self.enabled = enabled
        self.id = id
        self.secret = secret
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case id
        case secret
    }
}
