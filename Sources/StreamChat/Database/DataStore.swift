//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

protocol EntityCache {
    func get(userID: String) -> UserDTO?
    func set(user: UserDTO)

    func get(channelCID: String) -> ChannelDTO?
    func set(channel: ChannelDTO)

    func get(memberID: String) -> MemberDTO?
    func set(member: MemberDTO, channelId: ChannelId)

    func get(messageID: String) -> MessageDTO?
    func set(message: MessageDTO)

    func flush()
}

class InMemCache: EntityCache {
    static var shared = InMemCache()

    static let channels = "channels"
    static let members = "members"
    static let messages = "messages"
    static let users = "users"

    func flush() {
        // ["EntityCache"]["users"] -> UserDTO
        Thread.current.threadDictionary.removeObject(forKey: "EntityCache")
    }

    func makeKey(entityType: String, key: String) -> String {
        "\(entityType):\(key)"
    }

    func get<T>(entityType: String, key: String) -> T? {
        return nil
        if let dict = Thread.current.threadDictionary["EntityCache"] as? NSMutableDictionary {
            return dict[makeKey(entityType: entityType, key: key)] as? T
        }
        return nil
    }
    
    func set<T>(entityType: String, key: String, value: T) {
        if let dict = Thread.current.threadDictionary["EntityCache"] as? NSMutableDictionary {
            dict[makeKey(entityType: entityType, key: key)] = value
        } else {
            let dict = NSMutableDictionary()
            dict[makeKey(entityType: entityType, key: key)] = value
            Thread.current.threadDictionary["EntityCache"] = dict
        }
    }
    
    func get(messageID: String) -> MessageDTO? {
        get(entityType: Self.messages, key: messageID)
    }

    func set(message: MessageDTO) {
        set(entityType: Self.messages, key: message.id, value: message)
    }

    func get(userID: String) -> UserDTO? {
        get(entityType: Self.users, key: userID)
    }

    func set(user: UserDTO) {
        set(entityType: Self.users, key: user.id, value: user)
    }
    
    func get(channelCID: String) -> ChannelDTO? {
        get(entityType: Self.channels, key: channelCID)
    }

    func set(channel: ChannelDTO) {
        set(entityType: Self.channels, key: channel.cid, value: channel)
    }
    
    func get(memberID: String) -> MemberDTO? {
        get(entityType: Self.members, key: memberID)
    }

    func set(member: MemberDTO, channelId: ChannelId) {
        let memberId = MemberDTO.createId(userId: member.user.id, channeldId: channelId)
        set(entityType: Self.members, key: memberId, value: member)
    }
}

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
    public func user(id: UserId) -> ChatUser? {
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
    public func currentUser() -> CurrentChatUser? {
        database.viewContext.currentUser?.asModel()
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
    public func channel(cid: ChannelId) -> ChatChannel? {
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
    public func message(id: MessageId) -> ChatMessage? {
        database.viewContext.message(id: id)?.asModel()
    }
}
