//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnbanActionRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Channel CID for channel-specific unban
    var channelCid: String?
    /// Reason for the appeal decision
    var decisionReason: String?
    /// Also remove the future channels ban for this user
    var removeFutureChannelsBan: Bool?

    init(channelCid: String? = nil, decisionReason: String? = nil, removeFutureChannelsBan: Bool? = nil) {
        self.channelCid = channelCid
        self.decisionReason = decisionReason
        self.removeFutureChannelsBan = removeFutureChannelsBan
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case decisionReason = "decision_reason"
        case removeFutureChannelsBan = "remove_future_channels_ban"
    }

    static func == (lhs: UnbanActionRequestPayload, rhs: UnbanActionRequestPayload) -> Bool {
        lhs.channelCid == rhs.channelCid &&
            lhs.decisionReason == rhs.decisionReason &&
            lhs.removeFutureChannelsBan == rhs.removeFutureChannelsBan
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCid)
        hasher.combine(decisionReason)
        hasher.combine(removeFutureChannelsBan)
    }
}
