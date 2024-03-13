//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DataDogInfo: Codable, Hashable {
    public var apiKey: String
    public var enabled: Bool
    public var site: String

    public init(apiKey: String, enabled: Bool, site: String) {
        self.apiKey = apiKey
        self.enabled = enabled
        self.site = site
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case apiKey = "api_key"
        case enabled
        case site
    }
}
