//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

typealias ReminderResponsePayload = CreateReminderResponse
typealias RemindersQueryPayload = QueryRemindersResponse

extension ReminderPayload {
    convenience init(
        channelCid: ChannelId,
        messageId: MessageId,
        message: MessagePayload? = nil,
        channel: ChannelDetailPayload? = nil,
        remindAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.init(
            channel: channel,
            channelCid: channelCid.rawValue,
            createdAt: createdAt,
            message: message,
            messageId: messageId,
            remindAt: remindAt,
            updatedAt: updatedAt,
            userId: ""
        )
    }
}
