//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

class ChannelRepository {
    let database: DatabaseContainer
    let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

    /// Marks a channel as read
    /// - Parameters:
    ///   - cid: Channel id of the channel to be marked as read
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markRead(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markRead(cid: cid)) { [weak self] in
            self?.database.write { session in
                session.markChannelAsRead(cid: cid, userId: userId, at: .init())
            }
            completion?($0.error)
        }
    }

    /// Marks a subset of the messages of the channel as unread. All the following messages, including the one that is
    /// passed as parameter, will be marked as not read.
    /// - Parameters:
    ///   - messageId: The id of the first message id that will be marked as unread.
    ///   - cid: The id of the channel to be marked as unread
    ///   - userId: The id of the current user
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markUnread(
        from messageId: MessageId,
        cid: ChannelId,
        userId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .markUnread(cid: cid, messageId: messageId, userId: userId)
        ) { [weak self] result in
            self?.database.write { session in
                session.markChannelAsUnread(from: messageId, cid: cid, by: userId)
            }
            completion?(result.error)
        }
    }
}
