//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeviceResponse: Sendable, Codable, JSONEncodable {
    /// Date/time of creation
    let createdAt: Date
    /// Whether device is disabled or not
    let disabled: Bool?
    /// Reason explaining why device had been disabled
    let disabledReason: String?
    /// Stable physical device identifier used to deduplicate pushes across push providers
    let hardwareId: String?
    /// Device ID
    let id: String
    /// Push provider
    let pushProvider: String
    /// Push provider name
    let pushProviderName: String?
    /// User ID
    let userId: String
    /// When true the token is for Apple VoIP push notifications
    let voip: Bool?

    init(createdAt: Date, disabled: Bool? = nil, disabledReason: String? = nil, hardwareId: String? = nil, id: String, pushProvider: String, pushProviderName: String? = nil, userId: String, voip: Bool? = nil) {
        self.createdAt = createdAt
        self.disabled = disabled
        self.disabledReason = disabledReason
        self.hardwareId = hardwareId
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.userId = userId
        self.voip = voip
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case disabled
        case disabledReason = "disabled_reason"
        case hardwareId = "hardware_id"
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case userId = "user_id"
        case voip
    }
}
