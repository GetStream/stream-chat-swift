//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class ChannelRepository: @unchecked Sendable {
    let database: DatabaseContainer
    let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
    
    func getChannel(for query: ChannelQuery, store: Bool, completion: @escaping @Sendable (Result<ChatChannel, Error>) -> Void) {
        apiClient.request(endpoint: query.endpoint) { [database] result in
            switch result {
            case .success(let channelPayload):
                database.write(converting: { session in
                    let dto = try session.saveChannel(payload: channelPayload)
                    let model = try dto.asModel()
                    // Currently there is no direct payload to model conversion available
                    // Therefore, the channel has to be added to the context and then converted.
                    if !store {
                        (session as? NSManagedObjectContext)?.rollback()
                    }
                    return model
                }, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Marks a channel as read
    /// - Parameters:
    ///   - cid: Channel id of the channel to be marked as read
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    /// Local unread state is cleared optimistically before the network request so the UI does not
    /// briefly show jump-to-unread / unread badges while the mark-read request is in flight.
    /// If the API call fails, the previous local read state is restored.
    func markRead(
        cid: ChannelId,
        userId: UserId,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        database.write(converting: { session in
            let previousReadState = PreviousChannelReadState(from: session.loadChannelRead(cid: cid, userId: userId))
            session.markChannelAsRead(cid: cid, userId: userId, at: .init())
            return previousReadState
        }, completion: { [weak self] result in
            switch result {
            case .failure(let dbError):
                completion?(dbError)
            case .success(let previousReadState):
                self?.apiClient.request(endpoint: .markRead(cid: cid)) { [weak self] apiResult in
                    if let error = apiResult.error {
                        self?.rollbackMarkRead(
                            cid: cid,
                            userId: userId,
                            to: previousReadState,
                            apiError: error,
                            completion: completion
                        )
                        return
                    }
                    completion?(nil)
                }
            }
        })
    }

    private func rollbackMarkRead(
        cid: ChannelId,
        userId: UserId,
        to previousReadState: PreviousChannelReadState?,
        apiError: Error,
        completion: (@Sendable (Error?) -> Void)?
    ) {
        database.write({ session in
            guard let previousReadState else { return }

            if previousReadState.existed {
                guard let read = session.loadChannelRead(cid: cid, userId: userId) else { return }
                read.lastReadAt = previousReadState.lastReadAt.bridgeDate
                read.lastReadMessageId = previousReadState.lastReadMessageId
                read.unreadMessageCount = previousReadState.unreadMessageCount
            } else {
                // The optimistic write created a read object that did not exist before.
                session.markChannelAsUnread(cid: cid, by: userId)
            }
        }, completion: { _ in
            completion?(apiError)
        })
    }

    /// Marks a channel as read locally, without making a network request.
    ///
    /// Used when server-side read events are disabled (e.g. livestream channels).
    /// - Parameters:
    ///   - cid: Channel id of the channel to be marked as read
    ///   - userId: The id of the current user
    ///   - completion: Called when the local write completes. Called with `Error` if the database write fails.
    func markReadLocally(
        cid: ChannelId,
        userId: UserId,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        database.write({ session in
            session.markChannelAsRead(cid: cid, userId: userId, at: .init())
        }, completion: { error in
            completion?(error)
        })
    }

    /// Marks a subset of the messages of the channel as unread. All the following messages including the one that is
    /// passed as parameter, will be marked as not read.
    /// - Parameters:
    ///   - cid: The id of the channel to be marked as unread
    ///   - userId: The id of the current user
    ///   - unreadCriteria: The id or timestamp of the first message that will be marked as unread.
    ///   - lastReadMessageId: The id of the last message that was read.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markUnread(
        for cid: ChannelId,
        userId: UserId,
        from unreadCriteria: MarkUnreadCriteria,
        lastReadMessageId: MessageId?,
        completion: (@Sendable (Result<ChatChannel, Error>) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .markUnread(cid: cid, payload: .init(criteria: unreadCriteria, userId: userId))
        ) { [weak self] result in
            if let error = result.error {
                completion?(.failure(error))
                return
            }

            nonisolated(unsafe) var channel: ChatChannel?
            self?.database.write({ session in
                session.markChannelAsUnread(
                    for: cid,
                    userId: userId,
                    from: unreadCriteria,
                    lastReadMessageId: lastReadMessageId,
                    lastReadAt: nil,
                    unreadMessagesCount: nil
                )
                channel = try session.channel(cid: cid)?.asModel()
            }, completion: { error in
                if let channel = channel, error == nil {
                    completion?(.success(channel))
                } else {
                    completion?(.failure(error ?? ClientError.ChannelNotCreatedYet()))
                }
            })
        }
    }
}

private struct PreviousChannelReadState: Sendable {
    let existed: Bool
    let lastReadAt: Date
    let lastReadMessageId: MessageId?
    let unreadMessageCount: Int32

    init(from read: ChannelReadDTO?) {
        if let read {
            existed = true
            lastReadAt = read.lastReadAt.bridgeDate
            lastReadMessageId = read.lastReadMessageId
            unreadMessageCount = read.unreadMessageCount
        } else {
            existed = false
            lastReadAt = .distantPast
            lastReadMessageId = nil
            unreadMessageCount = 0
        }
    }
}
