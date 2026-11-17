//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ScheduledMessage {
    static func mock(
        id: String = .unique,
        cid: ChannelId = .unique,
        channelName: String? = nil,
        channelImageURL: URL? = nil,
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
            channel: .init(cid: cid, name: channelName, imageURL: channelImageURL),
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
