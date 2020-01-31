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
    @objc dynamic var id: String = ""
    @objc dynamic var channel: Channel?
    let messages = List<Message>()
    let messageReads = List<MessageRead>()
    
    override public class func primaryKey() -> String? {
        return "id"
    }
    
    var asChannelResponse: StreamChatCore.ChannelResponse? {
        guard let channel = channel?.asChannel else {
            return nil
        }
        
        return StreamChatCore.ChannelResponse(channel: channel,
                                              messages: messages.compactMap({ $0.asMessage }),
                                              messageReads: messageReads.compactMap({ $0.asMessageRead }))
    }
    
    required init() {
        super.init()
    }
    
    init(_ channelResponse: StreamChatCore.ChannelResponse) {
        let channel = Channel(channelResponse.channel)
        id = channelResponse.channel.cid.description
        self.channel = channel
        messages.append(objectsIn: channelResponse.messages.map({ Message($0, channelRealmObject: channel) }))
        messageReads.append(objectsIn: channelResponse.messageReads.map({ MessageRead($0) }))
    }
}
