//
//  MemberRealmObject.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 20/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatCore
import RealmSwift

public final class MemberRealmObject: Object {
    
    @objc dynamic var user: UserRealmObject = UserRealmObject()
    @objc dynamic var role: String = ""
    @objc dynamic var created: Date = Date()
    @objc dynamic var updated: Date = Date()
    @objc dynamic var isInvited: Bool = false
    @objc dynamic var inviteAccepted: Date?
    @objc dynamic var inviteRejected: Date?
    
    public var asMember: Member? {
        guard let user = user.asUser, let role = Member.Role(rawValue: role) else {
            return nil
        }
        
        return Member(user,
                      role: role,
                      created: created,
                      updated: updated,
                      isInvited: isInvited,
                      inviteAccepted: inviteAccepted,
                      inviteRejected: inviteRejected)
    }
    
    required init() {}
    
    public init(member: Member) {
        user = UserRealmObject(user: member.user)
        role = member.role.rawValue
        created = member.created
        updated = member.updated
        isInvited = member.isInvited
        inviteAccepted = member.inviteAccepted
        inviteRejected = member.inviteRejected
    }
}
