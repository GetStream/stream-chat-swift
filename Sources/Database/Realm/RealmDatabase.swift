//
//  RealmDatabase.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 19/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import StreamChatCore

/// A Realm datase for Stream Chat.
public final class RealmDatabase: Database {
    public var user: User?
    
    public var logger: ClientLogger?
    
    public func channels(_ query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        return .empty()
    }
    
    public func channel(channelType: ChannelType, channelId: String, pagination: Pagination) -> Observable<ChannelResponse> {
        return .empty()
    }
    
    public func replies(for message: Message, pagination: Pagination) -> Observable<[Message]> {
        return .empty()
    }
    
    public func add(channels: [ChannelResponse]) {
        
    }
    
    public func addOrUpdate(channel: Channel) {
        
    }
    
    public func add(messages: [Message], to channel: Channel) {
        
    }
    
    public func add(replies: [Message], for message: Message) {
        
    }
    
    public func set(members: Set<Member>, for channel: Channel) {
        
    }
    
    public func add(members: Set<Member>, for channel: Channel) {
        
    }
    
    public func remove(members: Set<Member>, from channel: Channel) {
        
    }
    
    public func update(members: Set<Member>, from channel: Channel) {
        
    }
}
