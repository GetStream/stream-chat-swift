//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Device: Codable, Hashable {
    public var createdAt: Date
    public var id: String
    public var pushProvider: String
    public var disabled: Bool? = nil
    public var disabledReason: String? = nil
    public var pushProviderName: String? = nil
    public var voip: Bool? = nil

    public init(createdAt: Date, id: String, pushProvider: String, disabled: Bool? = nil, disabledReason: String? = nil, pushProviderName: String? = nil, voip: Bool? = nil) {
        self.createdAt = createdAt
        self.id = id
        self.pushProvider = pushProvider
        self.disabled = disabled
        self.disabledReason = disabledReason
        self.pushProviderName = pushProviderName
        self.voip = voip
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case id
        case pushProvider = "push_provider"
        case disabled
        case disabledReason = "disabled_reason"
        case pushProviderName = "push_provider_name"
        case voip
    }
}
