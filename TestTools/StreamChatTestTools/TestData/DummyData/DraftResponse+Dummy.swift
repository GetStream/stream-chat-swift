//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension QueryDraftsResponse {
    static func dummy(
        drafts: [DraftResponse] = [],
        duration: String = "",
        next: String? = nil
    ) -> QueryDraftsResponse {
        .init(drafts: drafts, duration: duration, next: next)
    }
}

extension GetDraftResponse {
    static func dummy(
        draft: DraftResponse = .dummy(),
        duration: String = ""
    ) -> GetDraftResponse {
        .init(draft: draft, duration: duration)
    }
}

extension DraftResponse {
    /// Returns dummy draft payload with the given values.
    static func dummy(
        cid: ChannelId? = nil,
        channelPayload: ChannelResponse? = nil,
        createdAt: Date = .unique,
        message: DraftPayloadResponse = .dummy(),
        quotedMessage: MessageResponse? = nil,
        parentId: String? = nil,
        parentMessage: MessageResponse? = nil
    ) -> DraftResponse {
        .init(
            channel: channelPayload,
            channelCid: cid?.rawValue ?? channelPayload?.cid ?? "",
            createdAt: createdAt,
            message: message,
            parentId: parentId,
            parentMessage: parentMessage,
            quotedMessage: quotedMessage
        )
    }
}

extension DraftPayloadResponse {
    static func dummy(
        id: String = .unique,
        text: String = .unique,
        command: String? = nil,
        args: String? = nil,
        showReplyInChannel: Bool = false,
        mentionedUsers: [UserResponse]? = nil,
        extraData: [String: RawJSON] = [:],
        attachments: [Attachment]? = nil,
        isSilent: Bool = false
    ) -> DraftPayloadResponse {
        .init(
            attachments: attachments,
            custom: extraData,
            id: id,
            mentionedUsers: mentionedUsers,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text
        )
    }
}
