//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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
