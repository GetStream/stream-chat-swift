//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

open class ChatUIChannelMember: ChatUIUser {
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
    
    public required init<ExtraData: UserExtraData>(member: _ChatChannelMember<ExtraData>, name: String?, imageURL: URL?) {
        memberRole = member.memberRole
        memberCreatedAt = member.memberCreatedAt
        memberUpdatedAt = member.memberUpdatedAt
        isInvited = member.isInvited
        inviteAcceptedAt = member.inviteAcceptedAt
        inviteRejectedAt = member.inviteRejectedAt
        
        super.init(user: member, name: name, imageURL: imageURL)
    }
    
    // QUESTION: How to get rid of this???
    public required init<ExtraData>(user: _ChatUser<ExtraData>, name: String?, imageURL: URL?) where ExtraData: UserExtraData {
        fatalError("init(user:name:imageURL:) has not been implemented")
    }
}
