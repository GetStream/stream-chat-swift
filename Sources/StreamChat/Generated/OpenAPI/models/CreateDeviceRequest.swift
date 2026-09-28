//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateDeviceRequestPushProvider: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let apn = CreateDeviceRequestPushProvider(rawValue: "apn")
    static let firebase = CreateDeviceRequestPushProvider(rawValue: "firebase")
    static let huawei = CreateDeviceRequestPushProvider(rawValue: "huawei")
    static let xiaomi = CreateDeviceRequestPushProvider(rawValue: "xiaomi")
}

final class CreateDeviceRequest: Sendable, Encodable, JSONEncodable {
    /// Device ID
    let id: String
    /// Push provider
    let pushProvider: CreateDeviceRequestPushProvider
    /// Push provider name
    let pushProviderName: String?

    init(id: String, pushProvider: CreateDeviceRequestPushProvider, pushProviderName: String? = nil) {
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
    }
}
