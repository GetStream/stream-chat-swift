//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ScheduledMessage {
    public static func mock(
        id: String = .unique,
        cid: ChannelId = .unique,
        channelName: String? = nil,
        channelMemberCount: Int = 0,
        channelMembers: [ChatChannelMember] = [],
        message: ChatMessage = .mock(),
        quotedMessageId: MessageId? = nil,
        scheduledAt: Date = .init(),
        status: ScheduledMessageStatus = .scheduled,
        failure: ScheduledMessageFailure? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init()
    ) -> ScheduledMessage {
        .init(
            id: id,
            cid: cid,
            channel: .init(cid: cid, name: channelName, imageURL: nil, memberCount: channelMemberCount, members: channelMembers),
            message: message,
            quotedMessageId: quotedMessageId,
            scheduledAt: scheduledAt,
            status: status,
            failure: failure,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
