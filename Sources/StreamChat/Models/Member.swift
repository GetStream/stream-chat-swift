//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat channel member. `ChatChannelMember` is an immutable snapshot of a chat channel member entity
/// at the given time.
///
/// - Note: `ChatChannelMember` is a typealias of `_ChatChannelMember` with default extra data. If you're using custom extra data,
/// create your own typealias of `ChatChannelMember`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatChannelMember = _ChatChannelMember<NoExtraData>

/// A type representing a chat channel member. `_ChatChannelMember` is an immutable snapshot of a channel entity at the given time.
///
/// - Note: `_ChatChannelMember` type is not meant to be used directly. If you're using default extra data, use `ChatChannelMember`
/// typealias instead. If you're using custom extra data, create your own typealias of `_ChatChannelMember`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatChannelMember<ExtraData: UserExtraData>: _ChatUser<ExtraData> {
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
        userRole: UserRole,
        userCreatedAt: Date,
        userUpdatedAt: Date,
        lastActiveAt: Date?,
        extraData: ExtraData,
        memberRole: MemberRole,
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
            userRole: userRole,
            createdAt: userCreatedAt,
            updatedAt: userUpdatedAt,
            lastActiveAt: lastActiveAt,
            extraData: extraData
        )
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

    public init(from decoder: Decoder) throws {
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
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "MemberRole string value `\(value)` doesn't match any of the known roles"
            )
        }
    }
}
