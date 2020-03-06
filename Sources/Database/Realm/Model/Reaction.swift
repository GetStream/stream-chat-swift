//
//  Reaction.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 27/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class Reaction: Object {
    
    @objc dynamic var type = ""
    @objc dynamic var score = 1
    @objc dynamic var user: User?
    @objc dynamic var created = Date.default
    @objc dynamic var messageId = ""
    
    var asReaction: StreamChatCore.Reaction? {
        guard let type = ReactionType(named: type) else {
            return nil
        }
        
        return StreamChatCore.Reaction(type: type, score: score, messageId: messageId, user: user?.asUser, created: created)
    }
    
    required init() {
        super.init()
    }
    
    init(_ reaction: StreamChatCore.Reaction) {
        type = reaction.type.name
        score = reaction.score
        created = reaction.created
        messageId = reaction.messageId
        
        if let user = reaction.user {
            self.user = User(user)
        }
    }
}

public final class ReactionCounts: Object {
    @objc dynamic var type = ""
    @objc dynamic var count = 0
    
    required init() {
        super.init()
    }
    
    init(type: String, count: Int) {
        self.type = type
        self.count = count
    }
}
