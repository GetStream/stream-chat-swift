//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat channel member. `ChatChannelMember` is an immutable snapshot of a chat channel member entity
/// at the given time.
///
/// - Note: `ChatChannelMember` is a typealias of `_ChatChannelMember` with default extra data. If you're using custom extra data,
/// create your own typealias of `ChatChannelMember`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
///
public typealias ChatChannelMember = _ChatChannelMember<NameAndImageExtraData>

/// A type representing a chat channel member. `_ChatChannelMember` is an immutable snapshot of a channel entity at the given time.
///
/// - Note: `_ChatChannelMember` type is not meant to be used directly. If you're using default extra data, use `ChatChannelMember`
/// typealias instead. If you're using custom extra data, create your own typealias of `_ChatChannelMember`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
///
@dynamicMemberLookup
public struct _ChatChannelMember<ExtraData: UserExtraData> {
    /// The role of the user within the channel.
    public let memberRole: MemberRole
    
    /// The date the user was added to the channel.
    public let memberCreatedAt: Date
    
    /// The date the membership was updated for the last time.
    public let memberUpdatedAt: Date
    
    /// Returns `true` if the member has been invited to the channel.
    public let isInvited: Bool
    
    /// If the member accepted a channel invitation, this field contains date of when the invitation was accepted,
    /// otherwise it's `nil`.
    public let inviteAcceptedAt: Date?
    
    /// If the member rejected a channel invitation, this field contains date of when the invitation was rejected,
    /// otherwise it's `nil`.
    public let inviteRejectedAt: Date?
    
    /// The channel identifier.
    public let cid: ChannelId
    
    /// The user.
    public let user: _ChatUser<ExtraData>
    
    public init(
        cid: ChannelId,
        user: _ChatUser<ExtraData>,
        memberRole: MemberRole,
        memberCreatedAt: Date,
        memberUpdatedAt: Date,
        isInvited: Bool,
        inviteAcceptedAt: Date?,
        inviteRejectedAt: Date?
    ) {
        self.cid = cid
        self.user = user
        self.memberRole = memberRole
        self.memberCreatedAt = memberCreatedAt
        self.memberUpdatedAt = memberUpdatedAt
        self.isInvited = isInvited
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
    }
}

extension _ChatChannelMember: Hashable {
    public static func == (lhs: _ChatChannelMember<ExtraData>, rhs: _ChatChannelMember<ExtraData>) -> Bool {
        lhs.user.id == rhs.user.id && lhs.cid == rhs.cid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user.id)
        hasher.combine(cid)
    }
}

extension _ChatChannelMember {
    public subscript<T>(dynamicMember keyPath: KeyPath<ExtraData, T>) -> T {
        user.extraData[keyPath: keyPath]
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<_ChatUser<ExtraData>, T>) -> T {
        user[keyPath: keyPath]
    }
}

/// An enum describing possible roles of a member in a channel.
public enum MemberRole: String, Codable, Hashable {
    /// This is the default role assigned to any member.
    case member
    
    /// Allows the member to perform moderation, e.g. ban users, add/remove users, etc.
    case moderator
    
    /// This role allows the member to perform more advanced actions. This role should be granted only to staff users.
    case admin

    /// This rele allows the member to perform destructive actions on the channel.
    case owner
}
