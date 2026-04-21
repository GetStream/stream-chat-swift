//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanActionRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum BanActionRequestPayloadDeleteMessages: String, Sendable, Codable, CaseIterable {
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

    /// Also ban user from all channels this moderator creates in the future
    var banFromFutureChannels: Bool?
    /// Ban only from specific channel
    var channelBanOnly: Bool?
    var channelCid: String?
    /// Message deletion mode: soft, pruning, or hard
    var deleteMessages: BanActionRequestPayloadDeleteMessages?
    /// Whether to ban by IP address
    var ipBan: Bool?
    /// Reason for the ban
    var reason: String?
    /// Whether this is a shadow ban
    var shadow: Bool?
    /// Optional: ban user directly without review item
    var targetUserId: String?
    /// Duration of ban in minutes
    var timeout: Int?

    init(banFromFutureChannels: Bool? = nil, channelBanOnly: Bool? = nil, channelCid: String? = nil, deleteMessages: BanActionRequestPayloadDeleteMessages? = nil, ipBan: Bool? = nil, reason: String? = nil, shadow: Bool? = nil, targetUserId: String? = nil, timeout: Int? = nil) {
        self.banFromFutureChannels = banFromFutureChannels
        self.channelBanOnly = channelBanOnly
        self.channelCid = channelCid
        self.deleteMessages = deleteMessages
        self.ipBan = ipBan
        self.reason = reason
        self.shadow = shadow
        self.targetUserId = targetUserId
        self.timeout = timeout
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case banFromFutureChannels = "ban_from_future_channels"
        case channelBanOnly = "channel_ban_only"
        case channelCid = "channel_cid"
        case deleteMessages = "delete_messages"
        case ipBan = "ip_ban"
        case reason
        case shadow
        case targetUserId = "target_user_id"
        case timeout
    }

    static func == (lhs: BanActionRequestPayload, rhs: BanActionRequestPayload) -> Bool {
        lhs.banFromFutureChannels == rhs.banFromFutureChannels &&
            lhs.channelBanOnly == rhs.channelBanOnly &&
            lhs.channelCid == rhs.channelCid &&
            lhs.deleteMessages == rhs.deleteMessages &&
            lhs.ipBan == rhs.ipBan &&
            lhs.reason == rhs.reason &&
            lhs.shadow == rhs.shadow &&
            lhs.targetUserId == rhs.targetUserId &&
            lhs.timeout == rhs.timeout
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(banFromFutureChannels)
        hasher.combine(channelBanOnly)
        hasher.combine(channelCid)
        hasher.combine(deleteMessages)
        hasher.combine(ipBan)
        hasher.combine(reason)
        hasher.combine(shadow)
        hasher.combine(targetUserId)
        hasher.combine(timeout)
    }
}
