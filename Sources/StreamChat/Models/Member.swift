//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat channel member. `ChatChannelMember` is an immutable snapshot of a channel entity at the given time.
public class ChatChannelMember: ChatUser {
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
    
    /// Returns the date if the member has archived the channel, otherwise nil.
    public let archivedAt: Date?
    
    /// Returns the date if the member has pinned the channel, otherwise nil.
    public let pinnedAt: Date?

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
    public let isShadowBannedFromChannel: Bool

    /// A boolean value that returns whether the user has muted the channel or not.
    public let notificationsMuted: Bool

    /// Any additional custom data associated with the member of the channel.
    public let memberExtraData: [String: RawJSON]

    init(
        id: String,
        name: String?,
        imageURL: URL?,
        isOnline: Bool,
        isBanned: Bool,
        isFlaggedByCurrentUser: Bool,
        userRole: UserRole,
        teamsRole: [String: UserRole]?,
        userCreatedAt: Date,
        userUpdatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        teams: Set<TeamId>,
        language: TranslationLanguage?,
        extraData: [String: RawJSON],
        memberRole: MemberRole,
        memberCreatedAt: Date,
        memberUpdatedAt: Date,
        isInvited: Bool,
        inviteAcceptedAt: Date?,
        inviteRejectedAt: Date?,
        archivedAt: Date?,
        pinnedAt: Date?,
        isBannedFromChannel: Bool,
        banExpiresAt: Date?,
        isShadowBannedFromChannel: Bool,
        notificationsMuted: Bool,
        avgResponseTime: Int?,
        memberExtraData: [String: RawJSON]
    ) {
        self.memberRole = memberRole
        self.memberCreatedAt = memberCreatedAt
        self.memberUpdatedAt = memberUpdatedAt
        self.isInvited = isInvited
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        self.archivedAt = archivedAt
        self.pinnedAt = pinnedAt
        self.isBannedFromChannel = isBannedFromChannel
        self.isShadowBannedFromChannel = isShadowBannedFromChannel
        self.banExpiresAt = banExpiresAt
        self.notificationsMuted = notificationsMuted
        self.memberExtraData = memberExtraData

        super.init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            userRole: userRole,
            teamsRole: teamsRole,
            createdAt: userCreatedAt,
            updatedAt: userUpdatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }

    /// Returns a new `ChatChannelMember` with the provided data replaced.
    /// - Parameters:
    ///  - name: The new name.
    ///  - imageURL: The new image URL.
    ///  - userExtraData: The new extra data for the user.
    ///  - memberExtraData: The new extra data for the member channel (only related to this channel membership).
    public func replacing(
        name: String?,
        imageURL: URL?,
        userExtraData: [String: RawJSON]?,
        memberExtraData: [String: RawJSON]?
    ) -> ChatChannelMember {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBannedFromChannel,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            userRole: userRole,
            teamsRole: teamsRole,
            userCreatedAt: userCreatedAt,
            userUpdatedAt: userUpdatedAt,
            deactivatedAt: userDeactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            extraData: userExtraData ?? [:],
            memberRole: memberRole,
            memberCreatedAt: memberCreatedAt,
            memberUpdatedAt: memberUpdatedAt,
            isInvited: isInvited,
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt,
            archivedAt: archivedAt,
            pinnedAt: pinnedAt,
            isBannedFromChannel: isBannedFromChannel,
            banExpiresAt: banExpiresAt,
            isShadowBannedFromChannel: isShadowBannedFromChannel,
            notificationsMuted: notificationsMuted,
            avgResponseTime: avgResponseTime,
            memberExtraData: memberExtraData ?? [:]
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
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .member:
            try container.encode("channel_member")
        case .moderator:
            try container.encode("channel_moderator")
        default:
            try container.encode(rawValue)
        }
    }
}

/// The member information when adding a member to a channel.
public struct MemberInfo {
    public var userId: UserId
    public var extraData: [String: RawJSON]?

    public init(userId: UserId, extraData: [String: RawJSON]? = nil) {
        self.userId = userId
        self.extraData = extraData
    }
}
