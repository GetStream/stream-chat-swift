//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A type representing a chat channel. `ChatChannel` is an immutable snapshot of a channel entity at the given time.
///
public struct ChatChannel {
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
    
    /// Flag for representing hidden state for the channel.
    public let isHidden: Bool
    
    /// The user which created the channel.
    public let createdBy: ChatUser?
    
    /// A configuration struct of the channel. It contains additional information about the channel settings.
    public let config: ChannelConfig
    
    /// Returns `true` if the channel is frozen.
    ///
    /// It's not possible to send new messages to a frozen channel.
    ///
    public let isFrozen: Bool
    
    /// The total number of members in the channel.
    public let memberCount: Int
    
    /// A list of members of this channel.
    ///
    /// Array is sorted and the most recently active members will be first.
    ///
    /// - Important: This list doesn't have to contain all members of the channel. To access the full list of members, create
    /// a `ChatChannelMemberListController` for this channel and use it to query all channel members.
    ///
    /// - Note: This property will contain no more than `ChatClientConfig.channel.lastActiveMembersLimit` members.
    ///
    public var lastActiveMembers: [ChatChannelMember] { _lastActiveMembers }
    @CoreDataLazy private var _lastActiveMembers: [ChatChannelMember]
    
    /// A list of currently typing users.
    public var currentlyTypingUsers: Set<ChatUser> { _currentlyTypingUsers }
    @CoreDataLazy private var _currentlyTypingUsers: Set<ChatUser>
    
    /// If the current user is a member of the channel, this variable contains the details about the membership.
    public let membership: ChatChannelMember?
    
    /// A list of users and/or channel members currently actively watching the channel.
    ///
    /// Array is sorted and the most recently active watchers will be first.
    ///
    /// - Important: This list doesn't have to contain all watchers of the channel. To access the full list of watchers, create
    /// a `ChatChannelWatcherListController` for this channel and use it to query all channel watchers.
    ///
    /// - Note: This property will contain no more than `ChatClientConfig.channel.lastActiveWatchersLimit` members.
    ///
    public var lastActiveWatchers: [ChatUser] { _lastActiveWatchers }
    @CoreDataLazy private var _lastActiveWatchers: [ChatUser]

    /// The total number of online members watching this channel.
    public let watcherCount: Int
    
    /// The team the channel belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this otherwise it is always nil
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    ///
    public let team: TeamId?
    
    /// The unread counts for the channel.
    public var unreadCount: ChannelUnreadCount { _unreadCount }
    @CoreDataLazy private var _unreadCount: ChannelUnreadCount
    
    /// An option to enable ban users.
//    public let banEnabling: BanEnabling
    
    /// Latest messages present on the channel.
    ///
    /// This field contains only the latest messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    ///
    /// - Important: The `latestMessages` property is loaded and evaluated lazily to maintain high performance.
    public var latestMessages: [ChatMessage] { _latestMessages }
    @CoreDataLazy private var _latestMessages: [ChatMessage]
    
    /// Pinned messages present on the channel.
    ///
    /// This field contains only the pinned messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    ///
    /// - Important: The `pinnedMessages` property is loaded and evaluated lazily to maintain high performance.
    public var pinnedMessages: [ChatMessage] { _pinnedMessages }
    @CoreDataLazy private var _pinnedMessages: [ChatMessage]
    
    /// Read states of the users for this channel.
    ///
    /// You can use this information to show to your users information about what messages were read by certain users.
    ///
    public let reads: [ChatChannelRead]

    /// Channel mute details. If `nil` the channel is not muted by the current user.
    ///
    /// - Important: The `muteDetails` property is loaded and evaluated lazily to maintain high performance.
    public var muteDetails: MuteDetails? { _muteDetails }

    /// Says whether the channel is muted by the current user.
    ///
    /// - Important: The `isMuted` property is loaded and evaluated lazily to maintain high performance.
    public var isMuted: Bool { muteDetails != nil }

    @CoreDataLazy private var _muteDetails: MuteDetails?
    
    /// Cooldown duration for the channel, if it's in slow mode.
    /// This value will be 0 if the channel is not in slow mode.
    /// This value is in seconds.
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    public let cooldownDuration: Int
    
    /// Additional data associated with the channel.
    public let extraData: [String: RawJSON]

    // MARK: - Internal
    
    /// A helper variable to cache the result of the filter for only banned members.
    //  lazy var bannedMembers: Set<ChatChannelMember> = Set(self.members.filter { $0.isBanned })
    
    /// A list of users to invite in the channel.
//    let invitedMembers: Set<ChatChannelMember> // TODO: Why is this not public?
    
    init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        isHidden: Bool,
        createdBy: ChatUser? = nil,
        config: ChannelConfig = .init(),
        isFrozen: Bool = false,
        lastActiveMembers: @escaping (() -> [ChatChannelMember]) = { [] },
        membership: ChatChannelMember? = nil,
        currentlyTypingUsers: @escaping () -> Set<ChatUser> = { [] },
        lastActiveWatchers: @escaping (() -> [ChatUser]) = { [] },
        team: TeamId? = nil,
        unreadCount: @escaping () -> ChannelUnreadCount = { .noUnread },
        watcherCount: Int = 0,
        memberCount: Int = 0,
        reads: [ChatChannelRead] = [],
        cooldownDuration: Int = 0,
        extraData: [String: RawJSON],
        latestMessages: @escaping (() -> [ChatMessage]) = { [] },
        pinnedMessages: @escaping (() -> [ChatMessage]) = { [] },
        muteDetails: @escaping () -> MuteDetails?,
        underlyingContext: NSManagedObjectContext?
    ) {
        self.cid = cid
        self.name = name
        self.imageURL = imageURL
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.isHidden = isHidden
        self.createdBy = createdBy
        self.config = config
        self.isFrozen = isFrozen
        self.membership = membership
        self.team = team
        self.watcherCount = watcherCount
        self.memberCount = memberCount
        self.reads = reads
        self.cooldownDuration = cooldownDuration
        self.extraData = extraData
        
        $_unreadCount = (unreadCount, underlyingContext)
        $_latestMessages = (latestMessages, underlyingContext)
        $_lastActiveMembers = (lastActiveMembers, underlyingContext)
        $_currentlyTypingUsers = (currentlyTypingUsers, underlyingContext)
        $_lastActiveWatchers = (lastActiveWatchers, underlyingContext)
        $_pinnedMessages = (pinnedMessages, underlyingContext)
        $_muteDetails = (muteDetails, underlyingContext)
    }
}

extension ChatChannel {
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

/// A type-erased version of `ChannelModel<CustomData>`. Not intended to be used directly.
public protocol AnyChannel {}
extension ChatChannel: AnyChannel {}

extension ChatChannel: Hashable {
    public static func == (lhs: ChatChannel, rhs: ChatChannel) -> Bool {
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
