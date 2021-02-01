//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat channel. `ChatChannel` is an immutable snapshot of a channel entity at the given time.
///
/// - Note: `ChatChannel` is a typealias of `_ChatChannel` with default extra data. If you're using custom extra data, create
/// your own typealias of `ChatChannel`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatChannel = _ChatChannel<NoExtraData>

/// A type representing a chat channel. `_ChatChannel` is an immutable snapshot of a channel entity at the given time.
///
/// - Note: `_ChatChannel` type is not meant to be used directly. If you're using default extra data, use `ChatChannel`
/// typealias instead. If you're using custom extra data, create your own typealias of `ChatChannel`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
@dynamicMemberLookup
public struct _ChatChannel<ExtraData: ExtraDataTypes> {
    /// The `ChannelId` of the channel.
    public let cid: ChannelId
    
    /// Name for this channel.
    public let name: String?
    
    /// Image (avatar) url for this channel.
    public let imageURL: URL?
    
    /// The date of the last message in the channel.
    public let lastMessageAt: Date?
    
    /// The date when the channel was created.
    public let createdAt: Date
    
    /// The date when the channel was updated.
    public let updatedAt: Date
    
    /// If the channel was deleted, this field contains the date of the deletion.
    public let deletedAt: Date?
    
    /// The user which created the channel.
    public let createdBy: _ChatUser<ExtraData.User>?
    
    /// A configuration struct of the channel. It contains additional information about the channel settings.
    public let config: ChannelConfig
    
    /// Returns `true` if the channel is frozen.
    ///
    /// It's not possible to send new messages to a frozen channel.
    ///
    public let isFrozen: Bool
    
    /// The total number of members in the channel.
    public let memberCount: Int
    
    /// A list of locally cached members objects.
    ///
    /// - Important: This list doesn't have to contain all members of the channel. To access the full list of members, create
    /// a `ChatChannelController` for this channel and use it to query all channel members.
    ///
    public let cachedMembers: Set<_ChatChannelMember<ExtraData.User>>
    
    /// A list of currently typing channel members.
    public let currentlyTypingMembers: Set<_ChatChannelMember<ExtraData.User>>
    
    /// A list of channel members currently online actively watching the channel.
    public let watchers: Set<_ChatUser<ExtraData.User>>

    /// The total number of online members watching this channel.
    public let watcherCount: Int
    
    /// The team the channel belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this, else it'll be nil.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    ///
//    public let team: String
    
    /// The unread counts for the channel.
    public let unreadCount: ChannelUnreadCount
    
    /// An option to enable ban users.
//    public let banEnabling: BanEnabling
    
    /// Latest messages present on the channel.
    ///
    /// This field contains only the latest messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    ///
    public let latestMessages: [_ChatMessage<ExtraData>]
    
    /// Read states of the users for this channel.
    ///
    /// You can use this information to show to your users information about what messages were read by certain users.
    ///
    public let reads: [_ChatChannelRead<ExtraData>]
    
    /// Additional data associated with the channel.
    ///
    /// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
    ///
    public let extraData: ExtraData.Channel
    
    // MARK: - Internal
    
    /// A helper variable to cache the result of the filter for only banned members.
    //  lazy var bannedMembers: Set<_ChatChannelMember<ExtraData.User>> = Set(self.members.filter { $0.isBanned })
    
    /// A list of users to invite in the channel.
//    let invitedMembers: Set<_ChatChannelMember<ExtraData.User>> // TODO: Why is this not public?
    
    init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        createdBy: _ChatUser<ExtraData.User>? = nil,
        config: ChannelConfig = .init(),
        isFrozen: Bool = false,
        members: Set<_ChatChannelMember<ExtraData.User>> = [],
        currentlyTypingMembers: Set<_ChatChannelMember<ExtraData.User>> = [],
        watchers: Set<_ChatUser<ExtraData.User>> = [],
//        team: String = "",
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
//        banEnabling: BanEnabling = .disabled,
        reads: [_ChatChannelRead<ExtraData>] = [],
        extraData: ExtraData.Channel,
//        invitedMembers: Set<_ChatChannelMember<ExtraData.User>> = [],
        latestMessages: [_ChatMessage<ExtraData>] = []
    ) {
        self.cid = cid
        self.name = name
        self.imageURL = imageURL
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.createdBy = createdBy
        self.config = config
        self.isFrozen = isFrozen
        cachedMembers = members
        self.currentlyTypingMembers = currentlyTypingMembers
        self.watchers = watchers
//        self.team = team
        self.unreadCount = unreadCount
        self.watcherCount = watcherCount
        self.memberCount = memberCount
//        self.banEnabling = banEnabling
        self.reads = reads
        self.extraData = extraData
//        self.invitedMembers = invitedMembers
        self.latestMessages = latestMessages
    }
}

extension _ChatChannel {
    /// The type of the channel.
    public var type: ChannelType { cid.type }
    
    /// Returns `true` if the channel was deleted.
    public var isDeleted: Bool { deletedAt != nil }
    
    /// Checks if read events evadable for the current user.
//    public var readEventsEnabled: Bool { /* config.readEventsEnabled && members.contains(Member.current) */ fatalError() }
    
    /// Returns `true` when the channel is a direct-message channel.
    /// A "direct message" channel is created when client sends only the user id's for the channel and not an explicit `cid`,
    /// so backend creates a `cid` based on member's `id`s
    public var isDirectMessageChannel: Bool { cid.id.hasPrefix("!members") }
    
    /// returns `true` if the channel has one or more unread messages for the current user.
    public var isUnread: Bool { unreadCount.messages > 0 }
}

/// Additional data fields `ChannelModel` can be extended with. You can use it to store your custom data related to a channel.
public protocol ChannelExtraData: ExtraData {}

extension _ChatChannel {
    public subscript<T>(dynamicMember keyPath: KeyPath<ExtraData.Channel, T>) -> T {
        extraData[keyPath: keyPath]
    }
}

/// A type-erased version of `ChannelModel<CustomData>`. Not intended to be used directly.
public protocol AnyChannel {}
extension _ChatChannel: AnyChannel {}

extension _ChatChannel: Hashable {
    public static func == (lhs: _ChatChannel<ExtraData>, rhs: _ChatChannel<ExtraData>) -> Bool {
        lhs.cid == rhs.cid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
    }
}

/// A struct describing unread counts for a channel.
public struct ChannelUnreadCount: Decodable, Equatable {
    /// The default value representing no unread messages.
    public static let noUnread = ChannelUnreadCount(messages: 0, mentionedMessages: 0)
    
    /// The total number of unread messages in the channel.
    public internal(set) var messages: Int
    
    /// The number of unread messages that mention the current user.
    public internal(set) var mentionedMessages: Int
}
