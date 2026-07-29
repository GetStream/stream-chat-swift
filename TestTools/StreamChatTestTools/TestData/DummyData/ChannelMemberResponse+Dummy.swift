//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChannelMemberResponse {
    static func dummy(
        archivedAt: Date? = nil,
        banned: Bool = false,
        channelRole: String = "channel_member",
        createdAt: Date = .unique,
        custom: [String: RawJSON] = [:],
        notificationsMuted: Bool = false,
        pinnedAt: Date? = nil,
        shadowBanned: Bool = false,
        updatedAt: Date = .unique,
        user: UserPayload = .dummy(userId: .unique)
    ) -> ChannelMemberResponse {
        .init(
            archivedAt: archivedAt,
            banned: banned,
            channelRole: channelRole,
            createdAt: createdAt,
            custom: custom,
            notificationsMuted: notificationsMuted,
            pinnedAt: pinnedAt,
            shadowBanned: shadowBanned,
            updatedAt: updatedAt,
            user: user,
            userId: user.id
        )
    }
}

extension MembersResponse {
    static func dummy(members: [ChannelMemberResponse] = []) -> MembersResponse {
        .init(duration: "", members: members)
    }
}

extension UpdateMemberPartialResponse {
    static func dummy(channelMember: ChannelMemberResponse? = nil) -> UpdateMemberPartialResponse {
        .init(channelMember: channelMember, duration: "")
    }
}
