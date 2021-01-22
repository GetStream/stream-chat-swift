//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Types conforming to this protocol automatically exposes public `dataStore` variable.
public protocol DataStoreProvider {
    associatedtype ExtraData: ExtraDataTypes
    var client: _ChatClient<ExtraData> { get }
}

extension DataStoreProvider {
    /// `DataStore` provide access to all locally available model objects based on their id.
    public var dataStore: DataStore<ExtraData> { .init(client: client) }
}

/// `DataStore` provide access to all locally available model objects based on their id.
public struct DataStore<ExtraData: ExtraDataTypes> {
    let database: DatabaseContainer
    
    // Technically, we need only `database` but we use a `Client` instance to get the extra data types from it.
    init(client: _ChatClient<ExtraData>) {
        database = client.databaseContainer
    }
    
    /// Loads a user model with a matching `id` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// - Returns: If there's a user object in the locally cached data matching the provided `id`, returns the matching
    /// model object. If a user object doesn't exist locally, returns `nil`.
    ///
    /// **Warning**: Should be called on the `main` thread only.
    ///
    /// - Parameter id: An id of a user.
    public func user(id: UserId) -> _ChatUser<ExtraData.User>? {
        database.viewContext.user(id: id)?.asModel()
    }
    
    /// Loads a current user model with a matching `id` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// **Warning**: Should be called on the `main` thread only.
    ///
    /// - Returns: If there's a current user object in the locally cached data, returns the matching
    /// model object. If a user object doesn't exist locally, returns `nil`.
    public func currentUser() -> _CurrentChatUser<ExtraData.User>? {
        database.viewContext.currentUser()?.asModel()
    }

    /// Loads a channel model with a matching `cid` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// **Warning**: Should be called on the `main` thread only.
    ///
    /// - Returns: If there's a channel object in the locally cached data matching the provided `cid`, returns the matching
    /// model object. If a channel object doesn't exist locally, returns `nil`.
    ///
    /// - Parameter cid: An cid of a channel.
    public func channel(cid: ChannelId) -> _ChatChannel<ExtraData>? {
        database.viewContext.channel(cid: cid)?.asModel()
    }
    
    /// Loads a message model with a matching `id` from the **local data store**.
    ///
    /// If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.
    ///
    /// **Warning**: Should be called on the `main` thread only.
    ///
    /// - Returns: If there's a message object in the locally cached data matching the provided `id`, returns the matching
    /// model object. If a user object doesn't exist locally, returns `nil`.
    ///
    /// - Parameter id: An id of a message.
    public func message(id: MessageId) -> _ChatMessage<ExtraData>? {
        database.viewContext.message(id: id)?.asModel()
    }
}
