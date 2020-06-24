//
// MemberModel.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias Member = MemberModel<NameAndImageExtraData>

public class MemberModel<ExtraData: UserExtraData>: UserModel<ExtraData> {
    // MARK: - Public
    
    /// The role of the user within the channel.
    public let channelRole: ChannelRole
    
    /// A created date.
    public let memberCreatedDate: Date
    
    /// A updated date.
    public let memberUpdatedDate: Date
    
    /// Checks if he was invited.
    public let isInvited: Bool
    
    /// A date when an invited was accepted.
    public let inviteAcceptedDate: Date?
    
    /// A date when an invited was rejected.
    public let inviteRejectedDate: Date?
    
    public init(
        id: String,
        isOnline: Bool,
        isBanned: Bool,
        userRole: UserRole,
        userCreatedDate: Date,
        userUpdatedDate: Date,
        lastActiveDate: Date?,
        extraData: ExtraData?,
        channelRole: ChannelRole,
        memberCreatedDate: Date,
        memberUpdatedDate: Date,
        isInvited: Bool,
        inviteAcceptedDate: Date?,
        inviteRejectedDate: Date?
    ) {
        self.channelRole = channelRole
        self.memberCreatedDate = memberCreatedDate
        self.memberUpdatedDate = memberUpdatedDate
        self.isInvited = isInvited
        self.inviteAcceptedDate = inviteAcceptedDate
        self.inviteRejectedDate = inviteRejectedDate
        
        super.init(id: id,
                   isOnline: isOnline,
                   isBanned: isBanned,
                   userRole: userRole,
                   createdDate: userCreatedDate,
                   updatedDate: userUpdatedDate,
                   lastActiveDate: lastActiveDate,
                   extraData: extraData)
    }
}

/// The role of the meber in the channel
public enum ChannelRole: String, Codable, Hashable {
    case member
    case moderator
    case admin
    case owner
}
