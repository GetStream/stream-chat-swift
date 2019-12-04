//
//  ChannelsResponse.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 03/12/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class ChannelsResponse: Object {
    @objc dynamic var id: String = ""
    let channelResponses = List<ChannelResponse>()
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    required init() {
        super.init()
    }
    
    init(channelsQueryId: String, channels: [StreamChatCore.ChannelResponse]) {
        id = channelsQueryId
        channelResponses.append(objectsIn: channels.map({ ChannelResponse($0) }))
    }
}
