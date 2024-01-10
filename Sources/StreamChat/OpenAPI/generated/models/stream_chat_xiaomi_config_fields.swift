//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatXiaomiConfigFields: Codable, Hashable {
    public var packageName: String?
    
    public var secret: String?
    
    public var enabled: Bool
    
    public init(packageName: String?, secret: String?, enabled: Bool) {
        self.packageName = packageName
        
        self.secret = secret
        
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case packageName = "package_name"
        
        case secret
        
        case enabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(packageName, forKey: .packageName)
        
        try container.encode(secret, forKey: .secret)
        
        try container.encode(enabled, forKey: .enabled)
    }
}
