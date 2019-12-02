//
//  Member.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 20/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class Member: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var user: User?
    @objc dynamic var role = ""
    @objc dynamic var created = Date.default
    @objc dynamic var updated = Date.default
    @objc dynamic var isInvited = false
    @objc dynamic var inviteAccepted: Date?
    @objc dynamic var inviteRejected: Date?
    
    public var asMember: StreamChatCore.Member? {
        guard let user = user?.asUser, let role = StreamChatCore.Member.Role(rawValue: role) else {
            return nil
        }
        
        return StreamChatCore.Member(user,
                                     role: role,
                                     created: created,
                                     updated: updated,
                                     isInvited: isInvited,
                                     inviteAccepted: inviteAccepted,
                                     inviteRejected: inviteRejected)
    }
    
    required init() {
        super.init()
    }
    
    public init(member: StreamChatCore.Member, channel: StreamChatCore.Channel) {
        id = "\(channel.cid)_\(member.user.id)"
        user = User(member.user)
        role = member.role.rawValue
        created = member.created
        updated = member.updated
        isInvited = member.isInvited
        inviteAccepted = member.inviteAccepted
        inviteRejected = member.inviteRejected
    }
}
