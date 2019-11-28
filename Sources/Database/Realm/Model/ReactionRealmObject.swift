//
//  ReactionRealmObject.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 27/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class ReactionRealmObject: Object {
    
    @objc dynamic var type = ""
    @objc dynamic var user: UserRealmObject?
    @objc dynamic var created = Date.default
    @objc dynamic var messageId = ""
    
    var asReaction: Reaction? {
        guard let type = ReactionType(rawValue: type) else {
            return nil
        }
        
        return Reaction(type: type, messageId: messageId, user: user?.asUser, created: created)
    }
    
    required init() {}
    
    init(_ reaction: Reaction) {
        type = reaction.type.rawValue
        created = reaction.created
        messageId = reaction.messageId
        
        if let user = reaction.user {
            self.user = UserRealmObject(user)
        }
    }
}

public final class ReactionCountsRealmObject: Object {
    @objc dynamic var type = ""
    @objc dynamic var count = 0
    
    required init() {}
    
    init(type: String, count: Int) {
        self.type = type
        self.count = count
    }
}
