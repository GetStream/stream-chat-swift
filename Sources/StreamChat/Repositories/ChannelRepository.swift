//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class ChannelRepository {
    let database: DatabaseContainer
    let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
    
    func getChannel(for query: ChannelQuery, store: Bool, completion: @escaping (Result<ChatChannel, Error>) -> Void) {
        apiClient.request(endpoint: .createChannel(query: query)) { [database] result in
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
    func markRead(
        cid: ChannelId,
        userId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .markRead(cid: cid)) { [weak self] result in
            if let error = result.error {
                completion?(error)
                return
            }

            self?.database.write({ session in
                session.markChannelAsRead(cid: cid, userId: userId, at: .init())
            }, completion: { error in
                completion?(error)
            })
        }
    }

    /// Marks a subset of the messages of the channel as unread. All the following messages, including the one that is
    /// passed as parameter, will be marked as not read.
    /// - Parameters:
    ///   - cid: The id of the channel to be marked as unread
    ///   - userId: The id of the current user
    ///   - messageId: The id of the first message that will be marked as unread.
    ///   - lastReadMessageId: The id of the last message that was read.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markUnread(
        for cid: ChannelId,
        userId: UserId,
        from messageId: MessageId,
        lastReadMessageId: MessageId?,
        completion: ((Result<ChatChannel, Error>) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .markUnread(cid: cid, messageId: messageId, userId: userId)
        ) { [weak self] result in
            if let error = result.error {
                completion?(.failure(error))
                return
            }

            var channel: ChatChannel?
            self?.database.write({ session in
                session.markChannelAsUnread(
                    for: cid,
                    userId: userId,
                    from: messageId,
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
