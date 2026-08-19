//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct CreateDeviceRequestPushProvider: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let apn = Self(rawValue: "apn")
    static let firebase = Self(rawValue: "firebase")
    static let huawei = Self(rawValue: "huawei")
    static let xiaomi = Self(rawValue: "xiaomi")
}

final class CreateDeviceRequest: Sendable, Codable, JSONEncodable {
    /// Stable physical device identifier used to deduplicate pushes across push providers (e.g. APNs VoIP and Firebase on the same iOS device). Distinct from 'id', which is the push token.
    let hardwareId: String?
    /// Device ID
    let id: String
    /// Push provider
    let pushProvider: CreateDeviceRequestPushProvider
    /// Push provider name
    let pushProviderName: String?
    /// When true the token is for Apple VoIP push notifications
    let voipToken: Bool?

    init(
        hardwareId: String? = nil,
        id: String,
        pushProvider: CreateDeviceRequestPushProvider,
        pushProviderName: String? = nil,
        voipToken: Bool? = nil
    ) {
        self.hardwareId = hardwareId
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.voipToken = voipToken
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case hardwareId = "hardware_id"
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case voipToken = "voip_token"
    }
}
