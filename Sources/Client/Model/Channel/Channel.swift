//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A Channel class.
public final class Channel: Codable {
    /// Coding keys for the decoding.
    public enum DecodingKeys: String, CodingKey {
        /// An channel id.
        case id
        /// A combination of channel id and type.
        case cid
        /// A type.
        case type
        /// A channel name.
        case name
        /// An image URL.
        case imageURL = "image"
        /// A last message date.
        case lastMessageDate = "last_message_at"
        /// A user created by.
        case createdBy = "created_by"
        /// A created date.
        case created = "created_at"
        /// A deleted date.
        case deleted = "deleted_at"
        /// A channel config.
        case config
        /// A frozen flag.
        case frozen
        /// Members.
        case members
        /// The team the channel belongs to.
        case team
        /// The total number of members in the channel
        case memberCount = "member_count"
        /// Cooldown duration for the channel, if it's in slow mode.
        /// This value will be 0 if the channel is not in slow mode.
        case cooldownDuration = "cooldown"
    }
    
    /// Coding keys for the encoding.
    enum EncodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
        case members
        case invites
        case team
    }
    
    /// A custom extra data type for channels.
    /// - Note: Use this variable to setup your own extra data type for decoding channels custom fields from JSON data.
    public static var extraDataType: ChannelExtraDataCodable.Type = ChannelExtraData.self
    
    /// A channel type.
    public let type: ChannelType
    /// A channel id.
    public let id: String
    /// A channel type + id.
    public let cid: ChannelId
    /// The last message date.
    public let lastMessageDate: Date?
    /// A channel created date.
    public let created: Date
    /// A channel deleted date.
    public let deleted: Date?
    /// A creator of the channel.
    public let createdBy: User?
    /// A config.
    public let config: Config
    /// Checks if the channel is frozen.
    public let frozen: Bool
    /// The current user is a member of the channel. If not, it will be nil.
    public var membership: Member?
    /// A list of channel members.
    public var members = Set<Member>()
    
    /// A members count.
    public var memberCount: Int { memberCountAtomic.get() }
    
    private(set) lazy var memberCountAtomic = Atomic<Int>(0, callbackQueue: .main) { [weak self] _, _ in
        if let self = self {
            self.onUpdate?(self)
        }
    }
    
    /// A list of channel watchers.
    public internal(set) var watchers = Set<User>()
    /// A list of users to invite in the channel.
    let invitedMembers: Set<Member>
    /// The team the channel belongs to. You need to enable multi-tenancy if you want to use this, else it'll be nil.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let team: String
    /// An extra data for the channel.
    public var extraData: ChannelExtraDataCodable?
    /// Check if the channel was deleted.
    public var isDeleted: Bool { deleted != nil }
    /// Checks if read events evalable for the current user.
    public var readEventsEnabled: Bool { config.readEventsEnabled && membership != nil }
    /// Returns the current unread count.
    public var unreadCount: ChannelUnreadCount { unreadCountAtomic.get() }
    /// Cooldown duration for the channel, if it's in slow mode.
    /// This value will be 0 if the channel is not in slow mode.
    public let cooldownDuration: Int
    
    private(set) lazy var unreadCountAtomic = Atomic<ChannelUnreadCount>(.noUnread, callbackQueue: .main) { [weak self] _, _ in
        if let self = self {
            self.onUpdate?(self)
        }
    }
    
    /// Online watchers in the channel.
    public var watcherCount: Int { watcherCountAtomic.get() }
    
    private(set) lazy var watcherCountAtomic = Atomic(0, callbackQueue: .main) { [weak self] _, _ in
        if let self = self {
            self.onUpdate?(self)
        }
    }
    
    let unreadMessageReadAtomic = Atomic<MessageRead?>(nil)
    /// Unread message state for the current user.
    public var unreadMessageRead: MessageRead? { unreadMessageReadAtomic.get() }
    /// Checks if the current status of the channel is unread.
    public var isUnread: Bool {
        // Backend doesn't send unreadCount for pending invites so
        // it's safer to compare `lastMessageDate` and `lastReadDate`
        if let lastMessageDate = lastMessageDate, let lastReadDate = unreadMessageRead?.lastReadDate {
            return lastMessageDate > lastReadDate
        }
        
        // We don't have these info, so we use unreadCount
        return unreadCount.messages > 0
    }

    /// An option to enable ban users.
    public var banEnabling = BanEnabling.disabled
    var bannedUsers = [User]()
    /// Checks if the channel is direct message type between 2 users.
    public var isDirectMessage: Bool { id.hasPrefix("!members") && members.count == 2 }
    /// An event when the channel was updated.
    public var onUpdate: OnUpdate<Channel>?
    /// Checks if the channel was decoded from a channel response.
    public let didLoad: Bool
    /// Checks if the channel is watching by the client.
    public var isWatched: Bool { Client.shared.isWatching(channel: self) }
    /// Naming strategy to generate a name and image for the channel based on members.
    /// Only takes effect when `extraData` is `nil`.
    public var namingStrategy: ChannelNamingStrategy? = DefaultNamingStrategy(maxUserNames: 1)
    
    private var subscriptionBag = SubscriptionBag()
    private lazy var nameAndImageForCurrentUser = ChannelExtraData(name: extraData?.name, imageURL: extraData?.imageURL)
    
    let currentUserTypingLastDateAtomic = Atomic<Date?>()
    let currentUserTypingTimerControlAtomic = Atomic<TimerControl?>()
    
    /// Checks for the channel data encoding is empty.
    var isEmpty: Bool { extraData == nil && members.isEmpty && invitedMembers.isEmpty && team.isBlank }
    
    /// Returns the current timestamp. Can be replaced in tests with mock time, if needed.
    var currentTime: () -> Date = { Date() }
    
    public init(
        type: ChannelType,
        id: String,
        members: [User],
        invitedMembers: [User],
        extraData: ChannelExtraDataCodable?,
        created: Date,
        deleted: Date?,
        createdBy: User?,
        lastMessageDate: Date?,
        frozen: Bool,
        team: String = "",
        namingStrategy: ChannelNamingStrategy? = DefaultNamingStrategy(maxUserNames: 1),
        config: Config
    ) {
        self.type = type
        self.id = id
        cid = ChannelId(type: type, id: id)
        self.members = Set(members.map(\.asMember))
        self.invitedMembers = Set(invitedMembers.map(\.asMember))
        self.extraData = extraData
        self.created = created
        self.deleted = deleted
        self.createdBy = createdBy
        self.lastMessageDate = lastMessageDate
        self.frozen = frozen
        self.team = team
        self.namingStrategy = namingStrategy
        self.config = config
        cooldownDuration = 0
        didLoad = false
        memberCountAtomic.set(members.count)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DecodingKeys.self)
        type = try container.decode(ChannelType.self, forKey: .type)
        let id = try container.decode(String.self, forKey: .id)
        self.id = id
        cid = try container.decode(ChannelId.self, forKey: .cid)
        let members = try container.decodeIfPresent([Member].self, forKey: .members) ?? []
        self.members = Set<Member>(members)
        if let membership = members.first(where: { $0.user.id == Client.shared.user.id }) {
            self.membership = membership
        }
        invitedMembers = Set<Member>()
        // Fallback because config doesn't come in message search and to avoid breaking API by making it optional
        let config = (try? container.decode(Config.self, forKey: .config)) ?? Config()
        self.config = config
        created = try container.decodeIfPresent(Date.self, forKey: .created) ?? config.created
        deleted = try container.decodeIfPresent(Date.self, forKey: .deleted)
        createdBy = try container.decodeIfPresent(User.self, forKey: .createdBy)
        lastMessageDate = try container.decodeIfPresent(Date.self, forKey: .lastMessageDate)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        team = try container.decodeIfPresent(String.self, forKey: .team) ?? ""
        cooldownDuration = try container.decodeIfPresent(Int.self, forKey: .cooldownDuration) ?? 0
        didLoad = true
        extraData = Channel.decodeChannelExtraData(from: decoder)
        memberCountAtomic.set(try container.decodeIfPresent(Int.self, forKey: .memberCount) ?? members.count)
    }
    
    /// Safely decode channel extra data and if it fail try to decode only default properties: name, imageURL.
    private static func decodeChannelExtraData(from decoder: Decoder) -> ChannelExtraDataCodable? {
        do {
            var extraData = try Self.extraDataType.init(from: decoder) // swiftlint:disable:this explicit_init
            extraData.imageURL = extraData.imageURL?.removingRandomSVG()
            return extraData
            
        } catch {
            ClientLogger.log(
                "🐴❌",
                level: .error,
                "Channel extra data decoding error: \(error). "
                    + "Trying to recover by only decoding name and imageURL"
            )
            
            guard let container = try? decoder.container(keyedBy: DecodingKeys.self) else {
                return nil
            }
            
            // Recovering the default channel extra data properties: name, imageURL.
            var extraData = ChannelExtraData()
            extraData.name = try? container.decodeIfPresent(String.self, forKey: .name)
            extraData.imageURL = try? container.decodeIfPresent(URL.self, forKey: .imageURL)?.removingRandomSVG()
            return extraData
        }
    }
    
    deinit {
        subscriptionBag.cancel()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a channel extra data")
        
        try container.encode(team, forKey: .team)
        
        var allMembers = members
        
        if !invitedMembers.isEmpty {
            allMembers = allMembers.union(invitedMembers)
            try container.encode(invitedMembers, forKey: .invites)
        }
        
        if !allMembers.isEmpty {
            try container.encode(allMembers, forKey: .members)
        }
    }
    
    /// Resets unread counts.
    public func resetUnreadCount(messageRead: MessageRead) {
        unreadMessageReadAtomic.set(messageRead)
        unreadCountAtomic.set(.noUnread)
    }
    
    /// Check is the user is banned for the channel.
    /// - Parameter user: a user.
    public func isBanned(_ user: User) -> Bool {
        bannedUsers.contains(user)
    }
}

// MARK: - Equatable

extension Channel: Equatable, CustomStringConvertible {
    public static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.cid == rhs.cid
    }
    
    public var description: String {
        let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(self).toOpaque()
        return "Channel<\(opaque)>:\(cid):\(name ?? "<NoName>")"
    }
}

// MARK: - Subscriptions

extension Channel {
    public func subscribe(
        forEvents eventTypes: Set<EventType> = EventType.channelEventTypes,
        _ callback: @escaping Client.OnEvent
    ) -> Cancellable {
        let validEvents = eventTypes.intersection(EventType.channelEventTypes)
        
        if validEvents.count != eventTypes.count, let logger = Client.shared.logger {
            let notValidEvents = eventTypes.subtracting(EventType.channelEventTypes)
            logger.log(
                "⚠️ The events \(notValidEvents) are not channel events "
                    + "and will never get handled by your completion handler. "
                    + "Please check the documentation on event for more information.",
                level: .error
            )
        }
        
        guard !validEvents.isEmpty else {
            return Subscription { _ in }
        }
        
        let subscription = Client.shared.subscribe(forEvents: validEvents, cid: cid, callback)
        subscriptionBag.add(subscription)
        return subscription
    }
    
    public func subscribeToUnreadCount(_ callback: @escaping Client.Completion<ChannelUnreadCount>) -> Cancellable {
        let subscription = Client.shared.subscribeToUnreadCount(for: self, callback)
        subscriptionBag.add(subscription)
        return subscription
    }
    
    public func subscribeToWatcherCount(_ callback: @escaping Client.Completion<Int>) -> Cancellable {
        let subscription = Client.shared.subscribeToWatcherCount(for: self, callback)
        subscriptionBag.add(subscription)
        return subscription
    }
}

// MARK: - Channel Extra Data Codable

extension Channel {
    /// A channel name.
    public var name: String? {
        get {
            if nameAndImageForCurrentUser.name == nil, let namingStrategy = namingStrategy {
                // Save generated name to nameAndImageForCurrentUser since there isn't any
                nameAndImageForCurrentUser.name = namingStrategy.name(
                    for: User.current,
                    members: members.map(\.user)
                )
            }
            return nameAndImageForCurrentUser.name
        }
        set {
            var object: ChannelExtraDataCodable = extraData ?? ChannelExtraData()
            object.name = newValue
            nameAndImageForCurrentUser.name = newValue
            extraData = object
        }
    }
    
    /// An image of the channel.
    public var imageURL: URL? {
        get {
            if nameAndImageForCurrentUser.imageURL == nil, let namingStrategy = namingStrategy {
                // Save generated imageURL to nameAndImageForCurrentUser since there isn't any
                nameAndImageForCurrentUser.imageURL = namingStrategy.imageURL(
                    for: User.current,
                    members: members.map(\.user)
                )
            }
            return nameAndImageForCurrentUser.imageURL
        }
        set {
            var object: ChannelExtraDataCodable = extraData ?? ChannelExtraData()
            object.imageURL = newValue
            nameAndImageForCurrentUser.imageURL = newValue
            extraData = object
        }
    }
}

// MARK: - Helpers

private extension Array where Element == Member {
    func channelName(default: String) -> String {
        if isEmpty {
            return `default`
        }
        
        guard count > 1 else {
            return self[0].user.isCurrent ? `default` : self[0].user.name
        }
        
        if count == 2 {
            return (self[0].user.isCurrent ? self[1] : self[0]).user.name
        }
        
        let notCurrentMembers = filter { !$0.user.isCurrent }
        return "\(notCurrentMembers[0].user.name) and \(notCurrentMembers.count - 1) others"
    }
}

// MARK: - Supporting Structs

/// A message response.
public struct MessageResponse: Decodable {
    /// A message.
    public let message: Message
    /// A reaction.
    public let reaction: Reaction?
    /// Owner channel of this message. Only available when a message is queried by its `id`.
    @NestedKey
    public var channel: Channel?
    
    enum CodingKeys: String, NestableCodingKey {
        case message
        case reaction
        case channel = "message/channel"
    }
}

/// An event response.
public struct EventResponse: Decodable {
    /// An event (see `Event`).
    public let event: Event
}

/// A file upload response.
public struct FileUploadResponse: Decodable {
    /// An uploaded file URL.
    public let file: URL
}

struct HiddenChannelRequest: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case clearHistory = "clear_history"
    }
    
    let userId: String
    let clearHistory: Bool
}

/// A hidden channel event response.
public struct HiddenChannelResponse: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case cid
        case clearHistory = "clear_history"
        /// A created date.
        case created = "created_at"
    }
    
    /// A channel type + id.
    public let cid: ChannelId
    /// The message history was cleared.
    public let clearHistory: Bool
    /// An event created date.
    public let created: Date
}

// MARK: - Hashable

extension Channel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
    }
}
