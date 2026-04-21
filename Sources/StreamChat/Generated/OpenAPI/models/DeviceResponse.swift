//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeviceResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    /// Whether device is disabled or not
    var disabled: Bool?
    /// Reason explaining why device had been disabled
    var disabledReason: String?
    /// Device ID
    var id: String
    /// Push provider
    var pushProvider: String
    /// Push provider name
    var pushProviderName: String?
    /// User ID
    var userId: String
    /// When true the token is for Apple VoIP push notifications
    var voip: Bool?

    init(createdAt: Date, disabled: Bool? = nil, disabledReason: String? = nil, id: String, pushProvider: String, pushProviderName: String? = nil, userId: String, voip: Bool? = nil) {
        self.createdAt = createdAt
        self.disabled = disabled
        self.disabledReason = disabledReason
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
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case userId = "user_id"
        case voip
    }

    static func == (lhs: DeviceResponse, rhs: DeviceResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.disabled == rhs.disabled &&
            lhs.disabledReason == rhs.disabledReason &&
            lhs.id == rhs.id &&
            lhs.pushProvider == rhs.pushProvider &&
            lhs.pushProviderName == rhs.pushProviderName &&
            lhs.userId == rhs.userId &&
            lhs.voip == rhs.voip
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(disabled)
        hasher.combine(disabledReason)
        hasher.combine(id)
        hasher.combine(pushProvider)
        hasher.combine(pushProviderName)
        hasher.combine(userId)
        hasher.combine(voip)
    }
}
