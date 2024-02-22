//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
actor UnreadMessagesInteractor {
    private let cid: ChannelId
    private let authenticationRepository: AuthenticationRepository
    private let messageRepository: MessageRepository
    private let channelUpdater: ChannelUpdater
    
    init(cid: ChannelId, channelUpdater: ChannelUpdater, authenticationRepository: AuthenticationRepository, messageRepository: MessageRepository) {
        self.authenticationRepository = authenticationRepository
        self.cid = cid
        self.channelUpdater = channelUpdater
        self.messageRepository = messageRepository
    }
    
    private var markingReadTask: Task<Void, Error>?
    private var markingUnreadTask: Task<Void, Error>?
    
    func markRead(_ channel: ChatChannel) async throws {
        // Wait for marking unread
        if let task = markingUnreadTask {
            _ = try? await task.value
        }
        
        if let active = markingReadTask {
            try await active.value
        } else {
            guard let currentUserId = authenticationRepository.currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
            guard let lastMessageAt = channel.lastMessageAt else { return }
            guard let userRead = channel.reads.first(where: { $0.user.id == currentUserId }) else { return }
            guard userRead.lastReadAt < lastMessageAt else { return }
            
            markingReadTask = Task {
                defer { markingReadTask = nil }
                try await channelUpdater.markRead(cid: cid, userId: currentUserId)
            }
            try await markingReadTask?.value
        }
    }
    
    func markUnread(from message: MessageId, in channel: ChatChannel) async throws {
        // Wait for marking read
        if let task = markingReadTask {
            _ = try? await task.value
        }
        
        if let active = markingUnreadTask {
            try await active.value
        } else {
            guard let currentUserId = authenticationRepository.currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
            markingUnreadTask = Task<Void, Error> {
                defer { markingUnreadTask = nil }
                let newReadMessageId: MessageId? = await {
                    do {
                        return try await messageRepository.message(before: message, in: cid)
                    } catch {
                        log.debug("Failed to fetch a message before \(message) in channel with \(cid)")
                        return nil
                    }
                }()
                try await channelUpdater.markUnread(cid: cid, userId: currentUserId, from: message, lastReadMessageId: newReadMessageId)
            }
            try await markingUnreadTask?.value
        }
    }
}
