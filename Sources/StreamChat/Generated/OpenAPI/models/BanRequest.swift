//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanRequestDeleteMessages: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let hard = BanRequestDeleteMessages(rawValue: "hard")
    static let pruning = BanRequestDeleteMessages(rawValue: "pruning")
    static let soft = BanRequestDeleteMessages(rawValue: "soft")
}

final class BanRequest: Sendable, Encodable, JSONEncodable {
    /// Channel where the ban applies
    let channelCid: String?
    let deleteMessages: BanRequestDeleteMessages?
    /// Optional explanation for the ban
    let reason: String?
    /// Whether this is a shadow ban
    let shadow: Bool?
    /// ID of the user to ban
    let targetUserId: String
    /// Duration of the ban in minutes
    let timeout: Int?

    init(
        channelCid: String? = nil,
        deleteMessages: BanRequestDeleteMessages? = nil,
        reason: String? = nil,
        shadow: Bool? = nil,
        targetUserId: String,
        timeout: Int? = nil
    ) {
        self.channelCid = channelCid
        self.deleteMessages = deleteMessages
        self.reason = reason
        self.shadow = shadow
        self.targetUserId = targetUserId
        self.timeout = timeout
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case deleteMessages = "delete_messages"
        case reason
        case shadow
        case targetUserId = "target_user_id"
        case timeout
    }
}
