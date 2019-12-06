//
//  RealmDatabase+Database.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 29/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import StreamChatCore
import RealmSwift

// MARK: - Database Protocol

extension RealmDatabase: Database {
    
    public func deleteAll() {
        Realm.default?.deleteAll()
    }
    
    public func channels(_ query: StreamChatCore.ChannelsQuery) -> Observable<[StreamChatCore.ChannelResponse]> {
        guard let realm = Realm.default,
            let channelResponsesRealmObject = realm.object(ofType: ChannelsResponse.self, forPrimaryKey: query.id) else {
            return .empty()
        }
        
        let channelResponses: [StreamChatCore.ChannelResponse] = channelResponsesRealmObject.channelResponses
            .compactMap({ channelResponse in
                guard let channel = channelResponse.channel?.asChannel else {
                    return nil
                }
                
                return StreamChatCore.ChannelResponse(channel: channel,
                                                      messages: channelResponse.messages.compactMap({ $0.asMessage }),
                                                      messageReads: channelResponse.messageReads.compactMap({ $0.asMessageRead }))
            })
        
        return .just(channelResponses)
    }
    
    private func channelResponse(with channelRealmObject: Channel, realm: Realm) -> StreamChatCore.ChannelResponse? {
        if let channel = channelRealmObject.asChannel {
            let messages = realm.objects(Message.self).filter("channel == %@", channelRealmObject)
            return StreamChatCore.ChannelResponse(channel: channel, messages: messages.compactMap({ $0.asMessage }))
        }
        
        return nil
    }
    
    public func channel(channelType: ChannelType,
                        channelId: String,
                        pagination: Pagination) -> Observable<StreamChatCore.ChannelResponse> {
        guard let realm = Realm.default else {
            return .empty()
        }
        
        if let channelRealmObject = realm.objects(Channel.self)
            .filter("id == %@ AND type == %@", channelId, channelType.rawValue).first,
            let channelResponse = channelResponse(with: channelRealmObject, realm: realm) {
            return .just(channelResponse)
        }
        
        return .empty()
    }
    
    public func replies(for message: StreamChatCore.Message, pagination: Pagination) -> Observable<[StreamChatCore.Message]> {
//        guard let realm = Realm.default else {
//            return .empty()
//        }
        
        return .empty()
    }
    
    public func add(channels: [StreamChatCore.ChannelResponse], query: ChannelsQuery) {
        guard let realm = Realm.default else {
            return
        }
        
        realm.write(orCatchError: "Add channels \(channels.count)") { realm in
            let queryId = query.id
            let channelsResponse: ChannelsResponse
            
            if let existsChannelsResponse = realm.object(ofType: ChannelsResponse.self, forPrimaryKey: queryId) {
                channelsResponse = existsChannelsResponse
                channelsResponse.add(channels: channels)
            } else {
                channelsResponse = ChannelsResponse(channelsQueryId: queryId, channels: channels)
            }
            
            realm.add(channelsResponse, update: .modified)
        }
    }
    
    public func addOrUpdate(channel: StreamChatCore.Channel) {
        guard let realm = Realm.default else {
            return
        }
        
        realm.write(orCatchError: "Add or update the channel \(channel.cid)") { realm in
            realm.add(Channel(channel), update: .modified)
        }
    }
    
    public func add(messages: [StreamChatCore.Message], to channel: StreamChatCore.Channel) {
//        guard let realm = Realm.default else {
//            return
//        }
        
    }
    
    public func add(replies: [StreamChatCore.Message], for message: StreamChatCore.Message) {
//        guard let realm = Realm.default else {
//            return
//        }
        
    }
    
    public func set(members: Set<StreamChatCore.Member>, for channel: StreamChatCore.Channel) {
//        guard let realm = Realm.default else {
//            return
//        }
        
    }
    
    public func add(members: Set<StreamChatCore.Member>, for channel: StreamChatCore.Channel) {
//        guard let realm = Realm.default else {
//            return
//        }
        
    }
    
    public func remove(members: Set<StreamChatCore.Member>, from channel: StreamChatCore.Channel) {
//        guard let realm = Realm.default else {
//            return
//        }
        
    }
    
    public func update(members: Set<StreamChatCore.Member>, from channel: StreamChatCore.Channel) {
//        guard let realm = Realm.default else {
//            return
//        }
        
    }
}
