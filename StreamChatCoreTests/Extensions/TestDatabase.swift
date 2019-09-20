//
//  TestDatabase.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 19/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
@testable import StreamChatCore

public final class TestDatabase: Database {
    public var user: User?
    var messages: [String: [Message]] = [:]
    
    public func channels(_ query: ChannelsQuery) -> Observable<[CbhannelResponse]> {
        print("🗄🗄🗄 fetch channels", query)
        return .empty()
    }
    
    public func channel(channelType: ChannelType, channelId: String, pagination: Pagination) -> Observable<ChannelResponse> {
        print("🗄 fetch channel:", channelType, channelId, pagination)
        
        return .just(ChannelResponse(channel: Channel(type: channelType, id: channelId),
                                     messages: messages[channelId, default: []]))
    }
    
    public func add(messages: [Message], for channel: Channel) {
        if messages.isEmpty {
            return
        }
        
        print("🗄 added messages:", messages.count, "for channel:", channel.cid)
        self.messages[channel.id, default: []].append(contentsOf: messages)
    }
    
    public init() {}
}
