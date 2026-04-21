//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanOptions: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum BanOptionsDeleteMessages: String, Sendable, Codable, CaseIterable {
        case hard
        case pruning
        case soft
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

    var deleteMessages: BanOptionsDeleteMessages?
    var duration: Int?
    var ipBan: Bool?
    var reason: String?
    var shadowBan: Bool?

    init(deleteMessages: BanOptionsDeleteMessages? = nil, duration: Int? = nil, ipBan: Bool? = nil, reason: String? = nil, shadowBan: Bool? = nil) {
        self.deleteMessages = deleteMessages
        self.duration = duration
        self.ipBan = ipBan
        self.reason = reason
        self.shadowBan = shadowBan
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case deleteMessages = "delete_messages"
        case duration
        case ipBan = "ip_ban"
        case reason
        case shadowBan = "shadow_ban"
    }

    static func == (lhs: BanOptions, rhs: BanOptions) -> Bool {
        lhs.deleteMessages == rhs.deleteMessages &&
            lhs.duration == rhs.duration &&
            lhs.ipBan == rhs.ipBan &&
            lhs.reason == rhs.reason &&
            lhs.shadowBan == rhs.shadowBan
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(deleteMessages)
        hasher.combine(duration)
        hasher.combine(ipBan)
        hasher.combine(reason)
        hasher.combine(shadowBan)
    }
}
