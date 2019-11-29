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
    
    public func channels(_ query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        guard let realm = Realm.default else {
            return .empty()
        }
        
        var channelResponses = [ChannelResponse]()
        let channelRealmObjects = realm.objects(ChannelRealmObject.self)
        
        for channelRealmObject in channelRealmObjects {
            if let channelResponse = channelResponse(with: channelRealmObject, realm: realm) {
                channelResponses.append(channelResponse)
            }
        }
        
        return .just(channelResponses)
    }
    
    private func channelResponse(with channelRealmObject: ChannelRealmObject, realm: Realm) -> ChannelResponse? {
        if let channel = channelRealmObject.asChannel {
            let messages = realm.objects(MessageRealmObject.self).filter("channel == %@", channelRealmObject)
            return ChannelResponse(channel: channel, messages: messages.compactMap({ $0.asMessage }))
        }
        
        return nil
    }
    
    public func channel(channelType: ChannelType, channelId: String, pagination: Pagination) -> Observable<ChannelResponse> {
        guard let realm = Realm.default else {
            return .empty()
        }
        
        if let channelRealmObject = realm.objects(ChannelRealmObject.self)
            .filter("id == %@ AND type == %@", channelId, channelType.rawValue).first,
            let channelResponse = channelResponse(with: channelRealmObject, realm: realm) {
            return .just(channelResponse)
        }
        
        return .empty()
    }
    
    public func replies(for message: Message, pagination: Pagination) -> Observable<[Message]> {
        guard let realm = Realm.default else {
            return .empty()
        }
        
        return .empty()
    }
    
    public func add(channels: [ChannelResponse]) {
        guard let realm = Realm.default else {
            return
        }
        
        realm.write(orCatchError: "Add channels \(channels.count)") { realm in
            channels.forEach { channelResponse in
                let channelRealmObject = ChannelRealmObject(channelResponse.channel)
                realm.add(channelRealmObject, update: .modified)
                
                channelResponse.messages.forEach { message in
                    realm.add(MessageRealmObject(message, channelRealmObject: channelRealmObject), update: .modified)
                }
            }
        }
    }
    
    public func addOrUpdate(channel: Channel) {
        guard let realm = Realm.default else {
            return
        }
        
        realm.write(orCatchError: "Add or update the channel \(channel.cid)") { realm in
            realm.add(ChannelRealmObject(channel), update: .modified)
        }
    }
    
    public func add(messages: [Message], to channel: Channel) {
        guard let realm = Realm.default else {
            return
        }

    }
    
    public func add(replies: [Message], for message: Message) {
        guard let realm = Realm.default else {
            return
        }

    }
    
    public func set(members: Set<Member>, for channel: Channel) {
        guard let realm = Realm.default else {
            return
        }

    }
    
    public func add(members: Set<Member>, for channel: Channel) {
        guard let realm = Realm.default else {
            return
        }

    }
    
    public func remove(members: Set<Member>, from channel: Channel) {
        guard let realm = Realm.default else {
            return
        }

    }
    
    public func update(members: Set<Member>, from channel: Channel) {
        guard let realm = Realm.default else {
            return
        }

    }
}
