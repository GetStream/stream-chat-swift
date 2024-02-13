//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct XiaomiConfigFields: Codable, Hashable {
    public var enabled: Bool
    public var packageName: String? = nil
    public var secret: String? = nil

    public init(enabled: Bool, packageName: String? = nil, secret: String? = nil) {
        self.enabled = enabled
        self.packageName = packageName
        self.secret = secret
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case packageName = "package_name"
        case secret
    }
}
