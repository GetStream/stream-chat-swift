//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object representing a device which can receive push notifications.
public final class Device: Sendable, Codable, JSONEncodable {
    /// The date when the device was created.
    public let createdAt: Date?
    /// Whether device is disabled or not
    public let disabled: Bool?
    /// Reason explaining why device had been disabled
    public let disabledReason: String?
    /// Stable physical device identifier used to deduplicate pushes across push providers
    public let hardwareId: String?
    /// The device identifier.
    public let id: String
    /// Push provider
    public let pushProvider: String
    /// Push provider name
    public let pushProviderName: String?
    /// User ID
    public let userId: String
    /// When true the token is for Apple VoIP push notifications
    public let voip: Bool?

    init(
        createdAt: Date? = nil,
        disabled: Bool? = nil,
        disabledReason: String? = nil,
        hardwareId: String? = nil,
        id: String,
        pushProvider: String,
        pushProviderName: String? = nil,
        userId: String,
        voip: Bool? = nil
    ) {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        self.disabledReason = try container.decodeIfPresent(String.self, forKey: .disabledReason)
        self.hardwareId = try container.decodeIfPresent(String.self, forKey: .hardwareId)
        self.id = try container.decode(String.self, forKey: .id)
        self.pushProvider = try container.decode(String.self, forKey: .pushProvider)
        self.pushProviderName = try container.decodeIfPresent(String.self, forKey: .pushProviderName)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.voip = try container.decodeIfPresent(Bool.self, forKey: .voip)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(disabled, forKey: .disabled)
        try container.encodeIfPresent(disabledReason, forKey: .disabledReason)
        try container.encodeIfPresent(hardwareId, forKey: .hardwareId)
        try container.encode(id, forKey: .id)
        try container.encode(pushProvider, forKey: .pushProvider)
        try container.encodeIfPresent(pushProviderName, forKey: .pushProviderName)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(voip, forKey: .voip)
    }
}

extension Device: Hashable {
    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.disabled == rhs.disabled &&
            lhs.disabledReason == rhs.disabledReason &&
            lhs.hardwareId == rhs.hardwareId &&
            lhs.id == rhs.id &&
            lhs.pushProvider == rhs.pushProvider &&
            lhs.pushProviderName == rhs.pushProviderName &&
            lhs.userId == rhs.userId &&
            lhs.voip == rhs.voip
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(disabled)
        hasher.combine(disabledReason)
        hasher.combine(hardwareId)
        hasher.combine(id)
        hasher.combine(pushProvider)
        hasher.combine(pushProviderName)
        hasher.combine(userId)
        hasher.combine(voip)
    }
}
