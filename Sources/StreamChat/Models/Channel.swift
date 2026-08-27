//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
import StreamCore

/// A type representing a chat channel. `ChatChannel` is an immutable snapshot of a channel entity at the given time.
///
public final class ChatChannel: @unchecked Sendable {
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

    /// If the channel was truncated, this field contains the user which truncated it.
    public let truncatedBy: ChatUser?

    /// Flag for representing hidden state for the channel.
    public let isHidden: Bool

    /// The user which created the channel.
    public let createdBy: ChatUser?

    /// A configuration struct of the channel. It contains additional information about the channel settings.
    public let config: ChannelConfig

    /// The list of tags associated with the channel.
    public let filterTags: Set<String>
    
    /// The list of actions that the current user can perform in a channel.
    public let ownCapabilities: Set<ChannelCapability>

    /// Returns `true` if the channel is frozen.
    ///
    /// It's not possible to send new messages to a frozen channel.
    ///
    public let isFrozen: Bool
    
    /// Returns `true` if the channel is disabled.
    public let isDisabled: Bool
    
    /// Returns `true` if the channel is blocked.
    ///
    /// It's not possible to send new messages to a blocked channel.
    ///
    public let isBlocked: Bool

    /// The total number of members in the channel.
    public let memberCount: Int
    
    /// The total number of messages in the channel.
    /// Only returns value if `count_messages` is configured for your app.
    public let messageCount: Int?

    /// A list of members of this channel.
    ///
    /// Array is sorted and the most recently active members will be first.
    ///
    /// - Important: This list doesn't have to contain all members of the channel. To access the full list of members, create
    /// a `ChatChannelMemberListController` for this channel and use it to query all channel members.
    ///
    /// - Note: This property will contain no more than `ChatClientConfig.channel.lastActiveMembersLimit` members.
    ///
    public let lastActiveMembers: [ChatChannelMember]

    /// A list of currently typing users.
    public let currentlyTypingUsers: Set<ChatUser>

    /// If the current user is a member of the channel, this variable contains the details about the membership.
    public let membership: ChatChannelMember?

    /// Returns `true`, if the channel is archived.
    public var isArchived: Bool {
        membership?.archivedAt != nil
    }
    
    /// Returns `true`, if the channel is pinned.
    public var isPinned: Bool {
        membership?.pinnedAt != nil
    }

    /// A list of users and/or channel members currently actively watching the channel.
    ///
    /// Array is sorted and the most recently active watchers will be first.
    ///
    /// - Important: This list doesn't have to contain all watchers of the channel. To access the full list of watchers, create
    /// a `ChatChannelWatcherListController` for this channel and use it to query all channel watchers.
    ///
    /// - Note: This property will contain no more than `ChatClientConfig.channel.lastActiveWatchersLimit` members.
    ///
    public let lastActiveWatchers: [ChatUser]

    /// The total number of online members watching this channel.
    public let watcherCount: Int

    /// The team the channel belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this otherwise it is always nil
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    ///
    public let team: TeamId?

    /// A flag indicating whether messages sent to the channel are automatically translated.
    public let isAutoTranslationEnabled: Bool

    /// The languages configured on the channel for automatically translating new messages.
    ///
    /// Takes effect when automatic translation is enabled for either the channel or the app.
    /// Messages can additionally be translated into languages spoken by other members, and
    /// translations are available in `ChatMessage.translations`.
    public let autoTranslationLanguages: Set<TranslationLanguage>

    /// The unread counts for the channel.
    public let unreadCount: ChannelUnreadCount

    /// Latest messages present on the channel. The first item of the array, is the most recent message.
    ///
    /// This field contains only the latest messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    ///
    /// The amount of latest messages is controlled by the `ChatClientConfig.LocalCaching.latestMessagesLimit`.
    public let latestMessages: [ChatMessage]

    /// Latest message present on the channel sent by current user even if sent on a thread.
    public let lastMessageFromCurrentUser: ChatMessage?

    /// Pinned messages present on the channel.
    ///
    /// This field contains only the pinned messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    public let pinnedMessages: [ChatMessage]
    
    /// Messages that are pending for moderation on the server.
    /// These messages are visible only for the user that sent them, until they are approved.
    public let pendingMessages: [ChatMessage]

    /// Read states of the users for this channel.
    ///
    /// You can use this information to show to your users information about what messages were read by certain users.
    ///
    public let reads: [ChatChannelRead]

    /// Channel mute details. If `nil` the channel is not muted by the current user.
    public let muteDetails: MuteDetails?

    /// Says whether the channel is muted by the current user.
    public var isMuted: Bool { muteDetails != nil }

    /// Cooldown duration for the channel, if it's in slow mode.
    /// This value will be 0 if the channel is not in slow mode.
    /// This value is in seconds.
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    public let cooldownDuration: Int

    /// Additional data associated with the channel.
    public let extraData: [String: RawJSON]

    /// The draft message in the channel.
    public let draftMessage: DraftMessage?

    /// A list of active live locations in the channel.
    public let activeLiveLocations: [SharedLocation]
    
    /// Push preference for the channel.
    public let pushPreference: PushPreference?

    // MARK: - Internal

    var hasUnread: Bool {
        unreadCount.messages > 0
    }

    init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        truncatedAt: Date? = nil,
        truncatedBy: ChatUser? = nil,
        isHidden: Bool,
        createdBy: ChatUser? = nil,
        config: ChannelConfig = .init(),
        filterTags: Set<String> = [],
        ownCapabilities: Set<ChannelCapability> = [],
        isFrozen: Bool = false,
        isDisabled: Bool = false,
        isBlocked: Bool = false,
        lastActiveMembers: [ChatChannelMember],
        membership: ChatChannelMember? = nil,
        currentlyTypingUsers: Set<ChatUser>,
        lastActiveWatchers: [ChatUser],
        team: TeamId? = nil,
        isAutoTranslationEnabled: Bool = false,
        autoTranslationLanguages: Set<TranslationLanguage> = [],
        unreadCount: ChannelUnreadCount,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        messageCount: Int? = nil,
        reads: [ChatChannelRead] = [],
        cooldownDuration: Int = 0,
        extraData: [String: RawJSON],
        latestMessages: [ChatMessage],
        lastMessageFromCurrentUser: ChatMessage?,
        pinnedMessages: [ChatMessage],
        pendingMessages: [ChatMessage],
        muteDetails: MuteDetails?,
        draftMessage: DraftMessage?,
        activeLiveLocations: [SharedLocation],
        pushPreference: PushPreference?
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
        self.filterTags = filterTags
        self.ownCapabilities = ownCapabilities
        self.isFrozen = isFrozen
        self.isDisabled = isDisabled
        self.isBlocked = isBlocked
        self.membership = membership
        self.team = team
        self.isAutoTranslationEnabled = isAutoTranslationEnabled
        self.autoTranslationLanguages = autoTranslationLanguages
        self.watcherCount = watcherCount
        self.memberCount = memberCount
        self.messageCount = messageCount
        self.reads = reads
        self.cooldownDuration = cooldownDuration
        self.extraData = extraData
        self.truncatedAt = truncatedAt
        self.truncatedBy = truncatedBy
        self.unreadCount = unreadCount
        self.latestMessages = latestMessages
        self.lastMessageFromCurrentUser = lastMessageFromCurrentUser
        self.lastActiveMembers = lastActiveMembers
        self.currentlyTypingUsers = currentlyTypingUsers
        self.lastActiveWatchers = lastActiveWatchers
        self.pinnedMessages = pinnedMessages
        self.muteDetails = muteDetails
        self.draftMessage = draftMessage
        self.activeLiveLocations = activeLiveLocations
        self.pendingMessages = pendingMessages
        self.pushPreference = pushPreference
    }

    /// Returns a new `ChatChannel` with the provided data replaced.
    public func replacing(
        name: String?,
        imageURL: URL?,
        extraData: [String: RawJSON]?
    ) -> ChatChannel {
        .init(
            cid: cid,
            name: name,
            imageURL: imageURL,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            truncatedAt: truncatedAt,
            truncatedBy: truncatedBy,
            isHidden: isHidden,
            createdBy: createdBy,
            config: config,
            filterTags: filterTags,
            ownCapabilities: ownCapabilities,
            isFrozen: isFrozen,
            isDisabled: isDisabled,
            isBlocked: isBlocked,
            lastActiveMembers: lastActiveMembers,
            membership: membership,
            currentlyTypingUsers: currentlyTypingUsers,
            lastActiveWatchers: lastActiveWatchers,
            team: team,
            isAutoTranslationEnabled: isAutoTranslationEnabled,
            autoTranslationLanguages: autoTranslationLanguages,
            unreadCount: unreadCount,
            watcherCount: watcherCount,
            memberCount: memberCount,
            reads: reads,
            cooldownDuration: cooldownDuration,
            extraData: extraData ?? [:],
            latestMessages: latestMessages,
            lastMessageFromCurrentUser: lastMessageFromCurrentUser,
            pinnedMessages: pinnedMessages,
            pendingMessages: pendingMessages,
            muteDetails: muteDetails,
            draftMessage: draftMessage,
            activeLiveLocations: activeLiveLocations,
            pushPreference: pushPreference
        )
    }

    /// Returns a new `ChatChannel` with the provided data changed.
    public func changing(
        name: String? = nil,
        imageURL: URL? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date? = nil,
        deletedAt: Date? = nil,
        updatedAt: Date? = nil,
        truncatedAt: Date? = nil,
        isHidden: Bool? = nil,
        createdBy: ChatUser? = nil,
        config: ChannelConfig? = nil,
        filterTags: Set<String>? = nil,
        ownCapabilities: Set<ChannelCapability>? = nil,
        isFrozen: Bool? = nil,
        isDisabled: Bool? = nil,
        isBlocked: Bool? = nil,
        reads: [ChatChannelRead]? = nil,
        members: [ChatChannelMember]? = nil,
        membership: ChatChannelMember?? = nil,
        memberCount: Int? = nil,
        watchers: [ChatUser]? = nil,
        watcherCount: Int? = nil,
        team: TeamId? = nil,
        cooldownDuration: Int? = nil,
        pinnedMessages: [ChatMessage]? = nil,
        pushPreference: PushPreference? = nil,
        currentlyTypingUsers: Set<ChatUser>? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> ChatChannel {
        // Resolve the coalesced values up front so the type-checker does not
        // have to evaluate all of them inside the single large initializer call.
        let newName = name ?? self.name
        let newImageURL = imageURL ?? self.imageURL
        let newLastMessageAt = lastMessageAt ?? self.lastMessageAt
        let newCreatedAt = createdAt ?? self.createdAt
        let newUpdatedAt = updatedAt ?? self.updatedAt
        let newDeletedAt = deletedAt ?? self.deletedAt
        let newTruncatedAt = truncatedAt ?? self.truncatedAt
        let newIsHidden = isHidden ?? self.isHidden
        let newCreatedBy = createdBy ?? self.createdBy
        let newConfig = config ?? self.config
        let newFilterTags = filterTags ?? self.filterTags
        let newOwnCapabilities = ownCapabilities ?? self.ownCapabilities
        let newIsFrozen = isFrozen ?? self.isFrozen
        let newIsDisabled = isDisabled ?? self.isDisabled
        let newIsBlocked = isBlocked ?? self.isBlocked
        let newMembers = members ?? lastActiveMembers
        let newMembership = membership ?? self.membership
        let newCurrentlyTypingUsers = currentlyTypingUsers ?? self.currentlyTypingUsers
        let newWatchers = watchers ?? lastActiveWatchers
        let newTeam = team ?? self.team
        let newWatcherCount = watcherCount ?? self.watcherCount
        let newMemberCount = memberCount ?? self.memberCount
        let newReads = reads ?? self.reads
        let newCooldownDuration = cooldownDuration ?? self.cooldownDuration
        let newExtraData = extraData ?? self.extraData
        let newPinnedMessages = pinnedMessages ?? self.pinnedMessages
        return .init(
            cid: cid,
            name: newName,
            imageURL: newImageURL,
            lastMessageAt: newLastMessageAt,
            createdAt: newCreatedAt,
            updatedAt: newUpdatedAt,
            deletedAt: newDeletedAt,
            truncatedAt: newTruncatedAt,
            truncatedBy: truncatedBy,
            isHidden: newIsHidden,
            createdBy: newCreatedBy,
            config: newConfig,
            filterTags: newFilterTags,
            ownCapabilities: newOwnCapabilities,
            isFrozen: newIsFrozen,
            isDisabled: newIsDisabled,
            isBlocked: newIsBlocked,
            lastActiveMembers: newMembers,
            membership: newMembership,
            currentlyTypingUsers: newCurrentlyTypingUsers,
            lastActiveWatchers: newWatchers,
            team: newTeam,
            isAutoTranslationEnabled: isAutoTranslationEnabled,
            autoTranslationLanguages: autoTranslationLanguages,
            unreadCount: unreadCount,
            watcherCount: newWatcherCount,
            memberCount: newMemberCount,
            reads: newReads,
            cooldownDuration: newCooldownDuration,
            extraData: newExtraData,
            latestMessages: latestMessages,
            lastMessageFromCurrentUser: lastMessageFromCurrentUser,
            pinnedMessages: newPinnedMessages,
            pendingMessages: pendingMessages,
            muteDetails: muteDetails,
            draftMessage: draftMessage,
            activeLiveLocations: activeLiveLocations,
            pushPreference: pushPreference
        )
    }
}

extension ChatChannel: Identifiable {
    public var id: String { cid.rawValue }
}

extension ChatChannel {
    /// The type of the channel.
    public var type: ChannelType { cid.type }

    /// Returns `true` if the channel was deleted.
    public var isDeleted: Bool { deletedAt != nil }

    /// Returns `true` when the channel is a direct-message channel.
    /// A "direct message" channel is created when client sends only the user id's for the channel and not an explicit `cid`,
    /// so backend creates a `cid` based on member's `id`s
    public var isDirectMessageChannel: Bool { cid.id.hasPrefix("!members") }

    /// Returns `true` if the channel has one or more unread messages for the current user.
    public var isUnread: Bool { unreadCount != .noUnread }

    /// Returns the user's read state for this channel.
    /// - Parameter userId: The ID of the user.
    /// - Returns: The read state, or `nil` if not found.
    public func read(for userId: UserId) -> ChatChannelRead? {
        reads.first { $0.user.id == userId }
    }

    /// Returns read states for users who have read the given message.
    ///
    /// A user is considered to have read a message when:
    /// - The user has a read state in the channel
    /// - The user's last read timestamp is after the message creation time
    /// - The user is not the author of the message
    ///
    /// - Parameter message: The message to check read status for.
    /// - Returns: Array of read states for users who have read the message.
    public func reads(for message: ChatMessage) -> [ChatChannelRead] {
        reads.filter { read in
            read.lastReadAt >= message.createdAt && read.user.id != message.author.id
        }
    }

    /// Returns read states for users who have delivered the given message.
    ///
    /// A user is considered to have delivered a message when:
    /// - The user has a read state in the channel
    /// - The user's last delivered timestamp is after the message creation time
    /// - The user is not the author of the message
    ///
    /// - Parameter message: The message to check delivery status for.
    /// - Returns: Array of read states for users who have delivered the message.
    public func deliveredReads(for message: ChatMessage) -> [ChatChannelRead] {
        reads.filter { read in
            // We add a 1 second error interval in case the delivery is instant.
            let lastDeliveredAt = read.lastDeliveredAt?.addingTimeInterval(1) ?? .distantPast
            let isNotCurrentUser = read.user.id != message.author.id
            return lastDeliveredAt >= message.createdAt && isNotCurrentUser
        }
    }
}

/// A type-erased version of `ChannelModel<CustomData>`. Not intended to be used directly.
public protocol AnyChannel {}
extension ChatChannel: AnyChannel {}

extension ChatChannel: Hashable {
    public static func == (lhs: ChatChannel, rhs: ChatChannel) -> Bool {
        guard lhs.cid == rhs.cid else { return false }
        guard lhs.updatedAt == rhs.updatedAt else { return false }
        guard lhs.lastMessageAt == rhs.lastMessageAt else { return false }
        guard lhs.muteDetails == rhs.muteDetails else { return false }
        guard lhs.reads == rhs.reads else { return false }
        guard lhs.latestMessages == rhs.latestMessages else { return false }
        guard lhs.name == rhs.name else { return false }
        guard lhs.watcherCount == rhs.watcherCount else { return false }
        guard lhs.createdAt == rhs.createdAt else { return false }
        guard lhs.cooldownDuration == rhs.cooldownDuration else { return false }
        guard lhs.createdBy == rhs.createdBy else { return false }
        guard lhs.deletedAt == rhs.deletedAt else { return false }
        guard lhs.extraData == rhs.extraData else { return false }
        guard lhs.imageURL == rhs.imageURL else { return false }
        guard lhs.isFrozen == rhs.isFrozen else { return false }
        guard lhs.isDisabled == rhs.isDisabled else { return false }
        guard lhs.isHidden == rhs.isHidden else { return false }
        guard lhs.memberCount == rhs.memberCount else { return false }
        guard lhs.membership == rhs.membership else { return false }
        guard lhs.team == rhs.team else { return false }
        guard lhs.truncatedAt == rhs.truncatedAt else { return false }
        guard lhs.truncatedBy == rhs.truncatedBy else { return false }
        guard lhs.isAutoTranslationEnabled == rhs.isAutoTranslationEnabled else { return false }
        guard lhs.autoTranslationLanguages == rhs.autoTranslationLanguages else { return false }
        guard lhs.filterTags == rhs.filterTags else { return false }
        guard lhs.ownCapabilities == rhs.ownCapabilities else { return false }
        guard lhs.draftMessage == rhs.draftMessage else { return false }
        guard lhs.activeLiveLocations.count == rhs.activeLiveLocations.count else { return false }
        guard lhs.pushPreference == rhs.pushPreference else { return false }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
    }
}

/// A struct describing unread counts for a channel.
public struct ChannelUnreadCount: Decodable, Equatable, Sendable {
    /// The default value representing no unread messages.
    public static let noUnread = ChannelUnreadCount(messages: 0, mentions: 0)

    /// The total number of unread messages in the channel.
    public let messages: Int

    /// The number of unread messages that mention the current user.
    public let mentions: Int

    public init(messages: Int, mentions: Int) {
        self.messages = messages
        self.mentions = mentions
    }
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
    @available(*, deprecated, message: "Calling capabilities are no longer part of channel capabilities.")
    var canJoinCall: Bool {
        ownCapabilities.contains(.joinCall)
    }

    /// Can the current user create a call in this channel.
    @available(*, deprecated, message: "Calling capabilities are no longer part of channel capabilities.")
    var canCreateCall: Bool {
        ownCapabilities.contains(.createCall)
    }

    /// Is slow mode active in this channel.
    var isSlowMode: Bool {
        ownCapabilities.contains(.slowMode)
    }

    /// Can the current user send a poll in this channel.
    var canSendPoll: Bool {
        ownCapabilities.contains(.sendPoll)
    }

    /// Can the current user cast a poll vote in this channel.
    var canCastPollVote: Bool {
        ownCapabilities.contains(.castPollVote)
    }

    /// Can the current user share location in this channel.
    var canShareLocation: Bool {
        ownCapabilities.contains(.shareLocation)
    }

    /// Can the current user mention the whole channel (`@channel`) in this channel.
    var canNotifyChannel: Bool {
        ownCapabilities.contains(.notifyChannel)
    }

    /// Can the current user mention a user group (`@group`) in this channel.
    var canNotifyGroup: Bool {
        ownCapabilities.contains(.notifyGroup)
    }

    /// Can the current user mention the online members (`@here`) in this channel.
    var canNotifyHere: Bool {
        ownCapabilities.contains(.notifyHere)
    }

    /// Can the current user mention members with a given role (`@role`) in this channel.
    var canNotifyRole: Bool {
        ownCapabilities.contains(.notifyRole)
    }
}
