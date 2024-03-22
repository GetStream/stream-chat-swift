//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    /// If the channel was truncated, this field contains the date of the truncation.
    public let truncatedAt: Date?

    /// Flag for representing hidden state for the channel.
    public let isHidden: Bool

    /// The user which created the channel.
    public let createdBy: ChatUser?

    /// A configuration struct of the channel. It contains additional information about the channel settings.
    public let config: ChannelConfig

    /// The list of actions that the current user can perform in a channel.
    public let ownCapabilities: Set<ChannelCapability>

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

    /// Latest messages present on the channel. The first item of the array, is the most recent message.
    ///
    /// This field contains only the latest messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    ///
    /// The amount of latest messages is controlled by the `ChatClientConfig.LocalCaching.latestMessagesLimit`.
    ///
    /// - Important: The `latestMessages` property is loaded and evaluated lazily to maintain high performance.
    public var latestMessages: [ChatMessage] { _latestMessages }
    // stream:annotation "Move to async"
    @CoreDataLazy private var _latestMessages: [ChatMessage]

    /// Latest message present on the channel sent by current user even if sent on a thread.
    ///
    /// - Important: The `lastMessageFromCurrentUser` property is loaded and evaluated lazily to maintain high performance.
    public var lastMessageFromCurrentUser: ChatMessage? { _lastMessageFromCurrentUser }
    @CoreDataLazy private var _lastMessageFromCurrentUser: ChatMessage?

    /// Pinned messages present on the channel.
    ///
    /// This field contains only the pinned messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    ///
    /// - Important: The `pinnedMessages` property is loaded and evaluated lazily to maintain high performance.
    public var pinnedMessages: [ChatMessage] { _pinnedMessages }
    // stream:annotation "Move to async"
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

    /// The channel message is supposed to be shown in channel preview.
    ///
    /// - Important: The `previewMessage` can differ from `latestMessages.first` (or even not be included into `latestMessages`)
    /// because the preview message is the last `non-deleted` message sent to the channel.
    public var previewMessage: ChatMessage? { _previewMessage }
    // stream:annotation "Move to async?"
    @CoreDataLazy private var _previewMessage: ChatMessage?

    // MARK: - Internal

    var hasUnread: Bool {
        unreadCount.messages > 0
    }

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
        truncatedAt: Date? = nil,
        isHidden: Bool,
        createdBy: ChatUser? = nil,
        config: ChannelConfig = .init(),
        ownCapabilities: Set<ChannelCapability> = [],
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
        lastMessageFromCurrentUser: @escaping (() -> ChatMessage?) = { nil },
        pinnedMessages: @escaping (() -> [ChatMessage]) = { [] },
        muteDetails: @escaping () -> MuteDetails?,
        previewMessage: @escaping () -> ChatMessage?,
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
        self.ownCapabilities = ownCapabilities
        self.isFrozen = isFrozen
        self.membership = membership
        self.team = team
        self.watcherCount = watcherCount
        self.memberCount = memberCount
        self.reads = reads
        self.cooldownDuration = cooldownDuration
        self.extraData = extraData
        self.truncatedAt = truncatedAt

        $_unreadCount = (unreadCount, underlyingContext)
        $_latestMessages = (latestMessages, underlyingContext)
        $_lastMessageFromCurrentUser = (lastMessageFromCurrentUser, underlyingContext)
        $_lastActiveMembers = (lastActiveMembers, underlyingContext)
        $_currentlyTypingUsers = (currentlyTypingUsers, underlyingContext)
        $_lastActiveWatchers = (lastActiveWatchers, underlyingContext)
        $_pinnedMessages = (pinnedMessages, underlyingContext)
        $_muteDetails = (muteDetails, underlyingContext)
        $_previewMessage = (previewMessage, underlyingContext)
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

    /// Returns `true` if the channel has one or more unread messages for the current user.
    public var isUnread: Bool { unreadCount != .noUnread }
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
    public static let noUnread = ChannelUnreadCount(messages: 0, mentions: 0)

    /// The total number of unread messages in the channel.
    public let messages: Int

    /// The number of unread messages that mention the current user.
    public let mentions: Int
}

public extension ChannelUnreadCount {
    @available(*, deprecated, renamed: "mentions")
    var mentionedMessages: Int { mentions }
}

/// An action that can be performed in a channel.
public struct ChannelCapability: RawRepresentable, ExpressibleByStringLiteral, Hashable {
    public var rawValue: String

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }

    /// Ability to ban channel members.
    public static var banChannelMembers: Self = "ban-channel-members"
    /// Ability to receive connect events.
    public static var connectEvents: Self = "connect-events"
    /// Ability to delete any message from the channel.
    public static var deleteAnyMessage: Self = "delete-any-message"
    /// Ability to delete the channel.
    public static var deleteChannel: Self = "delete-channel"
    /// Ability to delete own messages from the channel.
    public static var deleteOwnMessage: Self = "delete-own-message"
    /// Ability to flag a message.
    public static var flagMessage: Self = "flag-message"
    /// Ability to freeze or unfreeze the channel.
    public static var freezeChannel: Self = "freeze-channel"
    /// Ability to leave the channel (remove own membership).
    public static var leaveChannel: Self = "leave-channel"
    /// Ability to join channel (add own membership).
    public static var joinChannel: Self = "join-channel"
    /// Ability to mute the channel.
    public static var muteChannel: Self = "mute-channel"
    /// Ability to pin a message.
    public static var pinMessage: Self = "pin-message"
    /// Ability to quote a message.
    public static var quoteMessage: Self = "quote-message"
    /// Ability to receive read events.
    public static var readEvents: Self = "read-events"
    /// Ability to use message search.
    public static var searchMessages: Self = "search-messages"
    /// Ability to send custom events.
    public static var sendCustomEvents: Self = "send-custom-events"
    /// Ability to attach links to messages.
    public static var sendLinks: Self = "send-links"
    /// Ability to send a message.
    public static var sendMessage: Self = "send-message"
    /// Ability to send reactions.
    public static var sendReaction: Self = "send-reaction"
    /// Ability to thread reply to a message.
    public static var sendReply: Self = "send-reply"
    /// Ability to enable or disable slow mode.
    public static var setChannelCooldown: Self = "set-channel-cooldown"
    /// Ability to send and receive typing events.
    public static var sendTypingEvents: Self = "send-typing-events"
    /// Ability to update any message in the channel.
    public static var updateAnyMessage: Self = "update-any-message"
    /// Ability to update channel data.
    public static var updateChannel: Self = "update-channel"
    /// Ability to update channel members.
    public static var updateChannelMembers: Self = "update-channel-members"
    /// Ability to update own messages in the channel.
    public static var updateOwnMessage: Self = "update-own-message"
    /// Ability to upload message attachments.
    public static var uploadFile: Self = "upload-file"
    /// Ability to send and receive typing events.
    public static var typingEvents: Self = "typing-events"
    /// Indicates that channel slow mode is active.
    public static var slowMode: Self = "slow-mode"
    /// Ability to skip the slow mode when it's active.
    public static var skipSlowMode: Self = "skip-slow-mode"
    /// Ability to join a call.
    public static var joinCall: Self = "join-call"
    /// Ability to create a call.
    public static var createCall: Self = "create-call"
}

public extension ChatChannel {
    /// Can the current user ban members from this channel.
    var canBanChannelMembers: Bool {
        ownCapabilities.contains(.banChannelMembers)
    }

    /// Can the current user receive connect events from this channel.
    var canReceiveConnectEvents: Bool {
        ownCapabilities.contains(.connectEvents)
    }

    /// Can the current user delete any message from this channel.
    var canDeleteAnyMessage: Bool {
        ownCapabilities.contains(.deleteAnyMessage)
    }

    /// Can the current user delete the channel.
    var canDeleteChannel: Bool {
        ownCapabilities.contains(.deleteChannel)
    }

    /// Can the current user delete own messages from the channel.
    var canDeleteOwnMessage: Bool {
        ownCapabilities.contains(.deleteOwnMessage)
    }

    /// Can the current user flag a message in this channel.
    var canFlagMessage: Bool {
        ownCapabilities.contains(.flagMessage)
    }

    /// Can the current user freeze or unfreeze the channel.
    var canFreezeChannel: Bool {
        ownCapabilities.contains(.freezeChannel)
    }

    /// Can the current user leave the channel (remove own membership).
    var canLeaveChannel: Bool {
        ownCapabilities.contains(.leaveChannel)
    }

    /// Can the current user join the channel (add own membership).
    var canJoinChannel: Bool {
        ownCapabilities.contains(.joinChannel)
    }

    /// Can the current user mute the channel.
    var canMuteChannel: Bool {
        ownCapabilities.contains(.muteChannel)
    }

    /// Can the current user pin a message in this channel.
    var canPinMessage: Bool {
        ownCapabilities.contains(.pinMessage)
    }

    /// Can the current user quote a message in this channel.
    var canQuoteMessage: Bool {
        ownCapabilities.contains(.quoteMessage)
    }

    /// Can the current user receive read events from this channel.
    var canReceiveReadEvents: Bool {
        ownCapabilities.contains(.readEvents)
    }

    /// Can the current user use message search in this channel.
    var canSearchMessages: Bool {
        ownCapabilities.contains(.searchMessages)
    }

    /// Can the current user send custom events in this channel.
    var canSendCustomEvents: Bool {
        ownCapabilities.contains(.sendCustomEvents)
    }

    /// Can the current user attach links to messages in this channel.
    var canSendLinks: Bool {
        ownCapabilities.contains(.sendLinks)
    }

    /// Can the current user send a message in this channel.
    var canSendMessage: Bool {
        ownCapabilities.contains(.sendMessage)
    }

    /// Can the current user send reactions in this channel.
    var canSendReaction: Bool {
        ownCapabilities.contains(.sendReaction)
    }

    /// Can the current user thread reply to a message in this channel.
    var canSendReply: Bool {
        ownCapabilities.contains(.sendReply)
    }

    /// Can the current user enable or disable slow mode in this channel.
    var canSetChannelCooldown: Bool {
        ownCapabilities.contains(.setChannelCooldown)
    }

    /// Can the current user send and receive typing events in this channel.
    var canSendTypingEvents: Bool {
        ownCapabilities.contains(.sendTypingEvents)
    }

    /// Can the current user update any message in this channel.
    var canUpdateAnyMessage: Bool {
        ownCapabilities.contains(.updateAnyMessage)
    }

    /// Can the current user update channel data.
    var canUpdateChannel: Bool {
        ownCapabilities.contains(.updateChannel)
    }

    /// Can the current user update channel members.
    var canUpdateChannelMembers: Bool {
        ownCapabilities.contains(.updateChannelMembers)
    }

    /// Can the current user update own messages in this channel.
    var canUpdateOwnMessage: Bool {
        ownCapabilities.contains(.updateOwnMessage)
    }

    /// Can the current user upload message attachments in this channel.
    var canUploadFile: Bool {
        ownCapabilities.contains(.uploadFile)
    }

    /// Can the current user join a call in this channel.
    var canJoinCall: Bool {
        ownCapabilities.contains(.joinCall)
    }

    /// Can the current user create a call in this channel.
    var canCreateCall: Bool {
        ownCapabilities.contains(.createCall)
    }

    /// Is slow mode active in this channel.
    var isSlowMode: Bool {
        ownCapabilities.contains(.slowMode)
    }
}
