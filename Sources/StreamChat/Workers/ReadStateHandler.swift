//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A handler which enables marking channels read and unread.
///
/// Only one mark read or unread request is allowed to be active.
final class ReadStateHandler {
    private let authenticationRepository: AuthenticationRepository
    private let channelUpdater: ChannelUpdater
    private let messageRepository: MessageRepository
    @Atomic private var markingRead = false
    @Atomic private(set) var isMarkedAsUnread = false
    
    init(
        authenticationRepository: AuthenticationRepository,
        channelUpdater: ChannelUpdater,
        messageRepository: MessageRepository
    ) {
        self.authenticationRepository = authenticationRepository
        self.channelUpdater = channelUpdater
        self.messageRepository = messageRepository
    }
    
    func markRead(_ channel: ChatChannel, completion: @escaping (Error?) -> Void) {
        guard
            !markingRead,
            let currentUserId = authenticationRepository.currentUserId,
            let currentUserRead = channel.reads.first(where: { $0.user.id == currentUserId }),
            let lastMessageAt = channel.lastMessageAt,
            currentUserRead.lastReadAt < lastMessageAt
        else {
            completion(nil)
            return
        }
        markingRead = true
        channelUpdater.markRead(cid: channel.cid, userId: currentUserId) { error in
            self.markingRead = false
            self.isMarkedAsUnread = false
            completion(error)
        }
    }
    
    func markRead(_ channel: ChatChannel) async throws {
        try await withCheckedThrowingContinuation { continuation in
            markRead(channel) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func markUnread(
        from messageId: MessageId,
        in channel: ChatChannel,
        completion: @escaping (Result<ChatChannel, Error>) -> Void
    ) {
        guard !markingRead,
              let currentUserId = authenticationRepository.currentUserId
        else {
            completion(.success(channel))
            return
        }
        markingRead = true
        messageRepository.getMessage(before: messageId, in: channel.cid) { [weak self] result in
            switch result {
            case .success(let lastReadMessageId):
                self?.channelUpdater.markUnread(
                    cid: channel.cid,
                    userId: currentUserId,
                    from: messageId,
                    lastReadMessageId: lastReadMessageId
                ) { [weak self] result in
                    if case .success = result {
                        self?.isMarkedAsUnread = true
                    }
                    self?.markingRead = false
                    completion(result)
                }
            case .failure(let error):
                self?.markingRead = false
                completion(.failure(error))
            }
        }
    }
    
    func markUnread(
        from messageId: MessageId,
        in channel: ChatChannel
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            markUnread(
                from: messageId,
                in: channel
            ) { result in
                continuation.resume(with: result.error)
            }
        }
    }
}
