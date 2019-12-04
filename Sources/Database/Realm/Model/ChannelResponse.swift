//
//  ChannelResponse.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 03/12/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class ChannelResponse: Object {
    @objc dynamic var channel: Channel?
    let messages = List<Message>()
    let messageReads = List<MessageRead>()
    
    required init() {
        super.init()
    }
    
    init(_ channelResponse: StreamChatCore.ChannelResponse) {
        let channel = Channel(channelResponse.channel)
        self.channel = channel
        messages.append(objectsIn: channelResponse.messages.map({ Message($0, channelRealmObject: channel) }))
        messageReads.append(objectsIn: channelResponse.messageReads.map({ MessageRead($0) }))
    }
}
