//
//  MutedUser.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 20/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class MutedUser: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var user: User?
    @objc dynamic var created = Date.default
    @objc dynamic var updated = Date.default
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    public var asMutedUser: StreamChatCore.MutedUser? {
        guard let user = user?.asUser else {
            return nil
        }
        
        return StreamChatCore.MutedUser(user: user, created: created, updated: updated)
    }
    
    required init() {
        super.init()
    }
    
    public init(mutedUser: StreamChatCore.MutedUser, channel: StreamChatCore.Channel) {
        id = "\(channel.cid)_\(mutedUser.user.id)"
        user = User(mutedUser.user)
        created = mutedUser.created
        updated = mutedUser.updated
    }
}
