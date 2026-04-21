//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateDeviceRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
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

    /// Device ID
    var id: String
    /// Push provider
    var pushProvider: CreateDeviceRequestPushProvider
    /// Push provider name
    var pushProviderName: String?
    /// When true the token is for Apple VoIP push notifications
    var voipToken: Bool?

    init(id: String, pushProvider: CreateDeviceRequestPushProvider, pushProviderName: String? = nil, voipToken: Bool? = nil) {
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.voipToken = voipToken
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case voipToken = "voip_token"
    }

    static func == (lhs: CreateDeviceRequest, rhs: CreateDeviceRequest) -> Bool {
        lhs.id == rhs.id &&
            lhs.pushProvider == rhs.pushProvider &&
            lhs.pushProviderName == rhs.pushProviderName &&
            lhs.voipToken == rhs.voipToken
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(pushProvider)
        hasher.combine(pushProviderName)
        hasher.combine(voipToken)
    }
}
