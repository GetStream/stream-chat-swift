//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias Member = MemberModel<NameAndImageExtraData>

public class MemberModel<ExtraData: UserExtraData>: UserModel<ExtraData> {
    // MARK: - Public
    
    /// The role of the user within the channel.
    public let memberRole: MemberRole
    
    /// A created date.
    public let memberCreatedAt: Date
    
    /// A updated date.
    public let memberUpdatedAt: Date
    
    /// Checks if he was invited.
    public let isInvited: Bool
    
    /// A date when an invited was accepted.
    public let inviteAcceptedAt: Date?
    
    /// A date when an invited was rejected.
    public let inviteRejectedAt: Date?
    
    public init(
        id: String,
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
        inviteRejectedAt: Date?
    ) {
        self.memberRole = memberRole
        self.memberCreatedAt = memberCreatedAt
        self.memberUpdatedAt = memberUpdatedAt
        self.isInvited = isInvited
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        
        super.init(
            id: id,
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

/// The role of the meber in the channel
public enum MemberRole: String, Codable, Hashable {
    case member
    case moderator
    case admin
    case owner
}
