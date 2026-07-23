//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class CreateDeviceRequest: Sendable, Codable, JSONEncodable {
    enum CreateDeviceRequestPushProvider: String, Sendable, Codable, CaseIterable {
        case apn
        case firebase
        case huawei
        case xiaomi
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

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
