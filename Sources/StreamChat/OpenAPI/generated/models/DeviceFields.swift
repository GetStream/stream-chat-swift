//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DeviceFields: Codable, Hashable {
    public var id: String
    public var pushProvider: String
    public var pushProviderName: String? = nil
    public var voip: Bool? = nil

    public init(id: String, pushProvider: String, pushProviderName: String? = nil, voip: Bool? = nil) {
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.voip = voip
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case voip
    }
}
