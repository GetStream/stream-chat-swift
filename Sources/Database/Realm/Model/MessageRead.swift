//
//  MessageRead.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 03/12/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class MessageRead: Object {
    @objc dynamic var user: User?
    @objc dynamic var lastReadDate = Date.default
    
    var asMessageRead: StreamChatCore.MessageRead? {
        guard let user = user?.asUser else {
            return nil
        }
        
        return StreamChatCore.MessageRead(user: user, lastReadDate: lastReadDate)
    }
    
    required init() {
        super.init()
    }
    
    init(_ messageRead: StreamChatCore.MessageRead) {
        user = User(messageRead.user)
        lastReadDate = messageRead.lastReadDate
    }
}
