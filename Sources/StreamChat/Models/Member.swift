//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat channel member. `ChatChannelMember` is an immutable snapshot of a channel entity at the given time.
public class ChatChannelMember: ChatUser {
    /// The role of the user within the channel.
    public let memberRole: MemberRole

    /// The Channel Role of the user within the channel.
    public let channelMemberRole: MemberRole
    
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

    /// `true` if the member if banned from the channel.
    ///
    /// Learn more about banning in the [documentation](https://getstream.io/chat/docs/ios-swift/moderation/?language=swift#ban).
    public let isBannedFromChannel: Bool

    /// If the member is banned from the channel, this field contains the date when the ban expires.
    ///
    /// Learn more about banning in the [documentation](https://getstream.io/chat/docs/ios-swift/moderation/?language=swift#ban).
    public let banExpiresAt: Date?

    /// `true` if the member if shadow banned from the channel.
    ///
    /// Learn more about shadow banning in the [documentation](https://getstream.io/chat/docs/ios-swift/moderation/?language=swift#shadow-ban).
    ///
    // TODO: Make public when working on CIS-720
    internal let isShadowBannedFromChannel: Bool

    init(
        id: String,
        name: String?,
        imageURL: URL?,
        isOnline: Bool,
        isBanned: Bool,
        isFlaggedByCurrentUser: Bool,
        userRole: UserRole,
        userCreatedAt: Date,
        userUpdatedAt: Date,
        lastActiveAt: Date?,
        teams: Set<TeamId>,
        extraData: [String: RawJSON],
        memberRole: MemberRole,
        channelMemberRole: MemberRole,
        memberCreatedAt: Date,
        memberUpdatedAt: Date,
        isInvited: Bool,
        inviteAcceptedAt: Date?,
        inviteRejectedAt: Date?,
        isBannedFromChannel: Bool,
        banExpiresAt: Date?,
        isShadowBannedFromChannel: Bool
    ) {
        self.memberRole = memberRole
        self.channelMemberRole = channelMemberRole
        self.memberCreatedAt = memberCreatedAt
        self.memberUpdatedAt = memberUpdatedAt
        self.isInvited = isInvited
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        self.isBannedFromChannel = isBannedFromChannel
        self.isShadowBannedFromChannel = isShadowBannedFromChannel
        self.banExpiresAt = banExpiresAt
        
        super.init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            userRole: userRole,
            createdAt: userCreatedAt,
            updatedAt: userUpdatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            extraData: extraData
        )
    }
}

/// A  `struct` describing roles of a member in a channel.
/// There are some predefined types but any type can be introduced and sent by the backend.
public struct MemberRole: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension MemberRole {
    /// This is the default role assigned to any member.
    static let member = Self(rawValue: "member")

    /// Allows the member to perform moderation, e.g. ban users, add/remove users, etc.
    static let moderator = Self(rawValue: "moderator")

    /// This role allows the member to perform more advanced actions. This role should be granted only to staff users.
    static let admin = Self(rawValue: "admin")

    /// This role allows the member to perform destructive actions on the channel.
    static let owner = Self(rawValue: "owner")

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "member", "channel_member":
            self = .member
        case "moderator", "channel_moderator":
            self = .moderator
        case "admin":
            self = .admin
        case "owner":
            self = .owner
        default:
            self = MemberRole(rawValue: value)
        }
    }
}
