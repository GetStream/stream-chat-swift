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
    public let logger: ClientLogger?
    var channels = [ChannelResponse]()
    var messages: [Channel: [Message]] = [:]
    var replies: [String: [Message]] = [:]
    var members = Set<Member>()
    
    public init(logOptions: ClientLogger.Options = []) {
        logger = logOptions.logger(icon: "🗄", for: [.databaseError, .database, .databaseInfo])
    }
}

extension TestDatabase: Database {
    
    public func channels(_ query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        return .just(channels)
    }
    
    public func channel(channelType: ChannelType, channelId: String, pagination: Pagination) -> Observable<ChannelResponse> {
        guard let channel = messages.keys.first(where: { $0.id == channelId }) else {
            return .empty()
        }
        
        return .just(ChannelResponse(channel: channel, messages: messages[channel, default: []]))
    }
    
    public func add(channels: [ChannelResponse]) {
        self.channels = channels
    }
    
    public func addOrUpdate(channel: Channel) {
        print("⚠️", #function)
    }
    
    public func add(messages: [Message], to channel: Channel) {
        self.messages[channel, default: []].append(contentsOf: messages)
    }
    
    public func replies(for message: Message, pagination: Pagination) -> Observable<[Message]> {
        return .just(replies[message.id, default: []])
    }
    
    public func add(replies: [Message], for message: Message) {
        self.replies[message.id] = replies
    }
    
    public func set(members: Set<Member>, for channel: Channel) {
        self.members = members
    }
    
    public func add(members: Set<Member>, for channel: Channel) {
        self.members = self.members.union(members)
    }
    
    public func remove(members: Set<Member>, from channel: Channel) {
        members.forEach { member in
            self.members.remove(member)
        }
    }
    
    public func update(members: Set<Member>, from channel: Channel) {
        self.members = self.members.union(members)
    }
}
