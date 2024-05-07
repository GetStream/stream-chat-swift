//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0.0, *)
extension MessageRepository {
    /// Fetches messages from the database with a date range.
    func messages(from fromDate: Date, to toDate: Date, in cid: ChannelId) async throws -> [ChatMessage] {
        try await database.read { context in
            try MessageDTO.loadMessages(
                from: fromDate,
                to: toDate,
                in: cid,
                sortAscending: true,
                deletedMessagesVisibility: context.deletedMessagesVisibility ?? .alwaysVisible,
                shouldShowShadowedMessages: context.shouldShowShadowedMessages ?? true,
                context: context
            )
            .map { try $0.asModel() }
        }
    }
    
    /// Fetches a message id before the specified message when sorting by the creation date in the local database.
    func message(before id: MessageId, in cid: ChannelId) async throws -> MessageId? {
        try await database.read { context in
            let deletedMessagesVisibility = context.deletedMessagesVisibility ?? .alwaysVisible
            let shouldShowShadowedMessages = context.shouldShowShadowedMessages ?? true
            return try MessageDTO.loadMessage(
                before: id,
                cid: cid.rawValue,
                deletedMessagesVisibility: deletedMessagesVisibility,
                shouldShowShadowedMessages: shouldShowShadowedMessages,
                context: context
            )?.id
        }
    }
    
    /// Fetches replies from the database with a date range.
    func replies(from fromDate: Date, to toDate: Date, in message: MessageId) async throws -> [ChatMessage] {
        try await database.read { context in
            try MessageDTO.loadReplies(
                from: fromDate,
                to: toDate,
                in: message,
                sortAscending: true,
                deletedMessagesVisibility: context.deletedMessagesVisibility ?? .alwaysVisible,
                shouldShowShadowedMessages: context.shouldShowShadowedMessages ?? true,
                context: context
            )
            .map { try $0.asModel() }
        }
    }
}
