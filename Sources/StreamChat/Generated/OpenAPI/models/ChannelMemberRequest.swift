//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelMemberRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Role of the member in the channel
    var channelRole: String?
    var custom: [String: RawJSON]?
    var user: UserResponse?
    var userId: String

    init(channelRole: String? = nil, custom: [String: RawJSON]? = nil, user: UserResponse? = nil, userId: String) {
        self.channelRole = channelRole
        self.custom = custom
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelRole = "channel_role"
        case custom
        case user
        case userId = "user_id"
    }

    static func == (lhs: ChannelMemberRequest, rhs: ChannelMemberRequest) -> Bool {
        lhs.channelRole == rhs.channelRole &&
            lhs.custom == rhs.custom &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelRole)
        hasher.combine(custom)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
