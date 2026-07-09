//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Device: Sendable, Codable, JSONEncodable {
    /// Date/time of creation
    public let createdAt: Date?
    /// Whether device is disabled or not
    public let disabled: Bool?
    /// Reason explaining why device had been disabled
    public let disabledReason: String?
    /// Stable physical device identifier used to deduplicate pushes across push providers
    public let hardwareId: String?
    /// Device ID
    public let id: String
    /// Push provider
    public let pushProvider: String
    /// Push provider name
    public let pushProviderName: String?
    /// User ID
    public let userId: String
    /// When true the token is for Apple VoIP push notifications
    public let voip: Bool?

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
