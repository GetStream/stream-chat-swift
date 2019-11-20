//
//  MutedUserRealmObject.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 20/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatCore
import RealmSwift

public final class MutedUserRealmObject: Object {
    
    @objc dynamic var user: UserRealmObject = UserRealmObject()
    @objc dynamic var created: Date = Date()
    @objc dynamic var updated: Date = Date()
    
    public var asMutedUser: MutedUser? {
        guard let user = user.asUser else {
            return nil
        }
        
        return MutedUser(user: user, created: created, updated: updated)
    }
    
    required init() {}
    
    public init(mutedUser: MutedUser) {
        user = UserRealmObject(user: mutedUser.user)
        created = mutedUser.created
        updated = mutedUser.updated
    }
}
