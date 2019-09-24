//
//  TestDatabase.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 19/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
//@testable import StreamChatCore

public final class TestDatabase {
    public var user: User?
    var messages: [Channel: [Message]] = [:]
    var replies: [String: [Message]] = [:]
    
    public init() {}
}

extension TestDatabase: Database {
    public func channels(_ query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        print("🗄🗄🗄 fetch channels", query)
        return .empty()
    }
    
    public func channel(channelType: ChannelType, channelId: String, pagination: Pagination) -> Observable<ChannelResponse> {
        print("🗄 fetch channel:", channelType, channelId, pagination)
        
        guard let channel = messages.keys.first(where: { $0.id == channelId }) else {
            return .empty()
        }
        
        return .just(ChannelResponse(channel: channel, messages: messages[channel, default: []]))
    }
    
    public func add(messages: [Message], for channel: Channel) {
        if messages.isEmpty {
            return
        }
        
        print("🗄 added messages:", messages.count, "for channel:", channel.cid)
        self.messages[channel, default: []].append(contentsOf: messages)
    }
    
    public func replies(for message: Message, pagination: Pagination) -> Observable<[Message]> {
        print("🗄 fetch replies for message:", message.textOrArgs, pagination)
        return .just(replies[message.id, default: []])
    }
    
    public func add(replies: [Message], for message: Message) {
        print("🗄 added replies:", replies.count, "for message:", message.textOrArgs)
        self.replies[message.id] = replies
    }
    
    public func set(members: [Member], for channel: Channel) {}
    
    public func add(member: Member, for channel: Channel) {}
    
    public func remove(member: Member, from channel: Channel) {}
    
    public func update(member: Member, from channel: Channel) {}
}
