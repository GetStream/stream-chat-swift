//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension SearchAllResponse {
    func asModel(
        query: UnifiedSearchQuery,
        currentUserId: UserId?,
        modelsTransformer: StreamModelsTransformer?
    ) -> UnifiedSearchResults {
        UnifiedSearchResults(
            query: query,
            channels: UnifiedSearchSection(
                error: channels?.error?.asModel(),
                isRestarted: channels?.warning?.code == .cursorRejected,
                items: (channels?.channels ?? []).map { payload in
                    let channel = payload.asModel(
                        currentUserId: currentUserId,
                        currentlyTypingUsers: nil,
                        typingUsers: nil,
                        unreadCount: nil
                    )
                    return modelsTransformer?.transform(channel: channel) ?? channel
                },
                next: channels?.next
            ),
            messages: UnifiedSearchSection(
                error: messages?.error?.asModel(),
                isRestarted: messages?.warning?.code == .cursorRejected,
                items: (messages?.results ?? []).compactMap {
                    $0.message.asModel(currentUserId: currentUserId, modelsTransformer: modelsTransformer)
                },
                next: messages?.next
            ),
            users: UnifiedSearchSection(
                error: users?.error?.asModel(),
                isRestarted: users?.warning?.code == .cursorRejected,
                items: (users?.users ?? []).map { $0.asModel() },
                next: users?.next
            )
        )
    }
}

extension SearchAllSectionError {
    func asModel() -> ClientError.UnifiedSearchSectionFailed {
        ClientError.UnifiedSearchSectionFailed(code: .init(rawValue: code.rawValue), message: message)
    }
}

extension SearchResultMessage {
    func asModel(currentUserId: UserId?, modelsTransformer: StreamModelsTransformer?) -> UnifiedSearchMessage? {
        let channel = self.channel.map { payload in
            let channel = payload.asModel(currentUserId: currentUserId)
            return modelsTransformer?.transform(channel: channel) ?? channel
        }
        guard let cid = channel?.cid ?? (try? ChannelId(cid: self.cid)) else {
            log.error("Skipping the unified search message \(id) with an invalid cid: \(self.cid)")
            return nil
        }
        let message = asMessageResponse().asModel(cid: cid, currentUserId: currentUserId, channelReads: channel?.reads ?? [])
        return UnifiedSearchMessage(
            channel: channel,
            message: modelsTransformer?.transform(message: message) ?? message
        )
    }
}
