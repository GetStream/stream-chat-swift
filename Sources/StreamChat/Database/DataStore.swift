//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Types conforming to this protocol automatically exposes public `dataStore` variable.
public protocol DataStoreProvider {
    var client: ChatClient { get }
}

extension DataStoreProvider {
    /// `DataStore` provide access to all locally available model objects based on their id.
    public var dataStore: DataStore { .init(client: client) }
}

/// `DataStore` provide access to all locally available model objects based on their id.
public struct DataStore {
    let database: DatabaseContainer

    // Technically, we need only `database` but we use a `Client` instance to get the extra data types from it.
    init(client: ChatClient) {
        database = client.databaseContainer
    }
    
    init(database: DatabaseContainer) {
        self.database = database
    }

    /// Loads a user model with a matching `id` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// - Returns: If there's a user object in the locally cached data matching the provided `id`, returns the matching
    /// model object. If a user object doesn't exist locally, returns `nil`.
    ///
    /// - Parameter id: An id of a user.
    public func user(id: UserId) -> ChatUser? {
        try? database.readAndWait { try? $0.user(id: id)?.asModel() }
    }

    /// Loads a current user model with a matching `id` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// - Returns: If there's a current user object in the locally cached data, returns the matching
    /// model object. If a user object doesn't exist locally, returns `nil`.
    public func currentUser() -> CurrentChatUser? {
        try? database.readAndWait { try? $0.currentUser?.asModel() }
    }

    /// Loads a channel model with a matching `cid` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// - Returns: If there's a channel object in the locally cached data matching the provided `cid`, returns the matching
    /// model object. If a channel object doesn't exist locally, returns `nil`.
    ///
    /// - Parameter cid: An cid of a channel.
    public func channel(cid: ChannelId) -> ChatChannel? {
        try? database.readAndWait { try? $0.channel(cid: cid)?.asModel() }
    }

    /// Loads a message model with a matching `id` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// - Returns: If there's a message object in the locally cached data matching the provided `id`, returns the matching
    /// model object. If a user object doesn't exist locally, returns `nil`.
    ///
    /// - Parameter id: An id of a message.
    public func message(id: MessageId) -> ChatMessage? {
        try? database.readAndWait { try? $0.message(id: id)?.asModel() }
    }

    /// Loads a thread model with a matching `parentMessageId` from the **local data store**.
    ///
    /// If the thread doesn't exist locally, it's recommended to fetch it with `messageController.loadThread()`.
    ///
    /// - Returns: Returns the Thread object.
    ///
    /// - Parameter parentMessageId: The message id which is the root of a trhead.
    public func thread(parentMessageId: MessageId) -> ChatThread? {
        try? database.readAndWait { try? $0.thread(parentMessageId: parentMessageId, cache: nil)?.asModel() }
    }
}
