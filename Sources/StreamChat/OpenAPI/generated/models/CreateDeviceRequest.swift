//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CreateDeviceRequest: Codable, Hashable {
    public var id: String
    public var pushProvider: String
    public var pushProviderName: String? = nil
    public var voipToken: Bool? = nil

    public init(id: String, pushProvider: String, pushProviderName: String? = nil, voipToken: Bool? = nil) {
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.voipToken = voipToken
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case voipToken = "voip_token"
    }
}
