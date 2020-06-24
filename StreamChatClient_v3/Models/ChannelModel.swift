//
// ChannelModel.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelModel<ExtraData: ExtraDataTypes> {
    // MARK: - Public
    
    /// A channel type + id.
    public let cid: ChannelId
    
    /// The date of the last message in the channel.
    public let lastMessageDate: Date?
    
    /// The date when the channel was created.
    public let created: Date
    
    /// The date when the channel was updated.
    public let updated: Date
    
    /// If the channel weas deleted, this field contains the date of the deletion.
    public let deleted: Date?
    
    /// The user which created the channel.
    public let createdBy: UserModel<ExtraData.User>?
    
    /// A config.
    public let config: ChannelConfig
    
    /// Checks if the channel is frozen.
    public let frozen: Bool
    
    /// A list of channel members.
    public let members: Set<MemberModel<ExtraData.User>>
    
    /// A list of channel watchers.
    public let watchers: Set<UserModel<ExtraData.User>>
    
    /// The team the channel belongs to. You need to enable multi-tenancy if you want to use this, else it'll be nil.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let team: String
    
    /// Returns the current unread count.
    public let unreadCount: ChannelUnreadCount
    
    /// Online watchers in the channel.
    public let watcherCount: Int
    
    /// Unread message state for the current user.
    public let unreadMessageRead: MessageRead<ExtraData.User>?
    
    /// An option to enable ban users.
    public let banEnabling: BanEnabling
    
    /// Checks if the channel is watching by the client.
    public let isWatched: Bool
    
    public let extraData: ExtraData.Channel
    
    // MARK: - Internal
    
    /// A helper variable to cache the result of the filter for only banned members.
    //  lazy var bannedMembers: Set<MemberModel<ExtraData.User>> = Set(self.members.filter { $0.isBanned })
    
    /// A list of users to invite in the channel.
    let invitedMembers: Set<MemberModel<ExtraData.User>> // TODO: Why is this not public?
    
    internal init(
        id: ChannelId,
        lastMessageDate: Date? = nil,
        created: Date = .init(),
        updated: Date = .init(),
        deleted: Date? = nil,
        createdBy: UserModel<ExtraData.User>? = nil,
        config: ChannelConfig = .init(),
        frozen: Bool = false,
        members: Set<MemberModel<ExtraData.User>> = [],
        watchers: Set<UserModel<ExtraData.User>> = [],
        team: String = "",
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        unreadMessageRead: MessageRead<ExtraData.User>? = nil,
        banEnabling: BanEnabling = .disabled,
        isWatched: Bool = false,
        extraData: ExtraData.Channel,
        invitedMembers: Set<MemberModel<ExtraData.User>> = []
    ) {
        cid = id
        self.lastMessageDate = lastMessageDate
        self.created = created
        self.updated = updated
        self.deleted = deleted
        self.createdBy = createdBy
        self.config = config
        self.frozen = frozen
        self.members = members
        self.watchers = watchers
        self.team = team
        self.unreadCount = unreadCount
        self.watcherCount = watcherCount
        self.unreadMessageRead = unreadMessageRead
        self.banEnabling = banEnabling
        self.isWatched = isWatched
        self.extraData = extraData
        self.invitedMembers = invitedMembers
    }
}

extension ChannelModel {
    /// A channel type.
    public var type: ChannelType { cid.type }
    
    /// Check if the channel was deleted.
    public var isDeleted: Bool { deleted != nil }
    
    /// Checks if read events evalable for the current user.
    public var readEventsEnabled: Bool { /* config.readEventsEnabled && members.contains(Member.current) */ fatalError() }
    
    /// Checks if the channel is direct message type between 2 users.
    public var isDirectMessage: Bool { cid.id.hasPrefix("!members") && members.count == 2 }
    
    /// Checks if the current status of the channel is unread.
    public var isUnread: Bool { unreadCount.messages > 0 }
    
    /// Checks for the channel data encoding is empty.
    var isEmpty: Bool { /* extraData == nil && members.isEmpty && invitedMembers.isEmpty */ fatalError() }
}

/// A convenience `ChannelModel` typealias with no additional channel data.
public typealias Channel = ChannelModel<DefaultDataTypes>

public protocol ChannelExtraData: Codable & Hashable {}

/// A type-erased version of `ChannelModel<CustomData>`. Not intended to be used directly.
public protocol AnyChannel {}
extension ChannelModel: AnyChannel {}

/// An unread counts for a channel.
public struct ChannelUnreadCount: Decodable, Equatable {
    public static let noUnread = ChannelUnreadCount(messages: 0, mentionedMessages: 0)
    public internal(set) var messages: Int
    public internal(set) var mentionedMessages: Int
}

/// A message read state. User + last read date + unread message count.
public struct MessageRead<ExtraData: UserExtraData>: Hashable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadDate = "last_read"
        case unreadMessagesCount = "unread_messages"
    }
    
    /// A user (see `User`).
    public let user: UserModel<ExtraData>
    /// A last read date by the user.
    public let lastReadDate: Date
    /// Unread message count for the user.
    public let unreadMessagesCount: Int
    
    /// Init a message read.
    ///
    /// - Parameters:
    ///   - user: a user.
    ///   - lastReadDate: the last read date.
    ///   - unreadMessages: Unread message count
    public init(user: UserModel<ExtraData>, lastReadDate: Date, unreadMessagesCount: Int) {
        self.user = user
        self.lastReadDate = lastReadDate
        self.unreadMessagesCount = unreadMessagesCount
    }
    
    public static func == (lhs: MessageRead, rhs: MessageRead) -> Bool {
        lhs.user == rhs.user
    }
}

/// An option to enable ban users.
public enum BanEnabling {
    /// Disabled for everyone.
    case disabled
    
    /// Enabled for everyone.
    /// The default timeout in minutes until the ban is automatically expired.
    /// The default reason the ban was created.
    case enabled(timeoutInMinutes: Int?, reason: String?)
    
    /// Enabled for channel members with a role of moderator or admin.
    /// The default timeout in minutes until the ban is automatically expired.
    /// The default reason the ban was created.
    case enabledForModerators(timeoutInMinutes: Int?, reason: String?)
    
    /// The default timeout in minutes until the ban is automatically expired.
    public var timeoutInMinutes: Int? {
        switch self {
        case .disabled:
            return nil
            
        case let .enabled(timeout, _),
             let .enabledForModerators(timeout, _):
            return timeout
        }
    }
    
    /// The default reason the ban was created.
    public var reason: String? {
        switch self {
        case .disabled:
            return nil
            
        case let .enabled(_, reason),
             let .enabledForModerators(_, reason):
            return reason
        }
    }
    
    /// Returns true is the ban is enabled for the channel.
    /// - Parameter channel: a channel.
    public func isEnabled(for channel: Channel) -> Bool {
        switch self {
        case .disabled:
            return false
            
        case .enabled:
            return true
            
        case .enabledForModerators:
            fatalError()
//      let members = Array(channel.members)
//      return members.first(where: { $0.user.isCurrent && ($0.role == .moderator || $0.role == .admin) }) != nil
        }
    }
}
