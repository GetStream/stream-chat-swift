//
//  ChannelRealmObject.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 19/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class ChannelRealmObject: Object, RealmObjectIndexable {
    
    @objc dynamic var id = ""
    @objc dynamic var type = ""
    @objc dynamic var name = ""
    @objc dynamic var imageURL: String?
    @objc dynamic var lastMessageDate: Date?
    @objc dynamic var created = Date.default
    @objc dynamic var deleted: Date?
    @objc dynamic var createdBy: UserRealmObject?
    @objc dynamic var frozen = false
    @objc dynamic var config: ChannelConfigRealmObject?
    @objc dynamic var extraData: Data?
    let members = List<MemberRealmObject>()
    
    public static var indexedPropertiesKeyPaths: [AnyKeyPath] = [\ChannelRealmObject.type,
                                                                 \ChannelRealmObject.created]
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    public var asChannel: Channel? {
        return Channel(type: ChannelType(rawValue: type),
                       id: id,
                       name: name,
                       imageURL: imageURL?.url,
                       lastMessageDate: lastMessageDate,
                       created: created,
                       deleted: deleted,
                       createdBy: createdBy?.asUser,
                       frozen: frozen,
                       members: members.compactMap({ $0.asMember }),
                       config: config?.asConfig ?? Channel.Config(),
                       extraData: ExtraData.ChannelWrapper.decode(extraData))
    }
    
    required init() {
        super.init()
    }
    
    public init(_ channel: Channel) {
        id = channel.id
        type = channel.type.rawValue
        name = channel.name
        imageURL = channel.imageURL?.absoluteString
        lastMessageDate = channel.lastMessageDate
        created = channel.created
        deleted = channel.deleted
        frozen = channel.frozen
        config = channel.config.isEmpty ? nil : ChannelConfigRealmObject(config: channel.config)
        extraData = channel.extraData?.encode()
        members.append(objectsIn: channel.members.map({ MemberRealmObject(member: $0, channel: channel) }))
        
        if let createdBy = channel.createdBy {
            self.createdBy = UserRealmObject(createdBy)
        }
    }
}

// MARK: - Config

public final class ChannelConfigRealmObject: Object {
    @objc dynamic var reactionsEnabled = false
    @objc dynamic var typingEventsEnabled = false
    @objc dynamic var readEventsEnabled = false
    @objc dynamic var connectEventsEnabled = false
    @objc dynamic var uploadsEnabled = false
    @objc dynamic var repliesEnabled = false
    @objc dynamic var searchEnabled = false
    @objc dynamic var mutesEnabled = false
    @objc dynamic var urlEnrichmentEnabled = false
    @objc dynamic var flagsEnabled = false
    @objc dynamic var messageRetention = ""
    @objc dynamic var maxMessageLength = 0
    @objc dynamic var created = Date.default
    @objc dynamic var updated = Date.default
    let commands = List<ChannelCommandRealmObject>()
    
    public var asConfig: Channel.Config {
        return Channel.Config(reactionsEnabled: reactionsEnabled,
                              typingEventsEnabled: typingEventsEnabled,
                              readEventsEnabled: readEventsEnabled,
                              connectEventsEnabled: connectEventsEnabled,
                              uploadsEnabled: uploadsEnabled,
                              repliesEnabled: repliesEnabled,
                              searchEnabled: searchEnabled,
                              mutesEnabled: mutesEnabled,
                              urlEnrichmentEnabled: urlEnrichmentEnabled,
                              flagsEnabled: flagsEnabled,
                              messageRetention: messageRetention,
                              maxMessageLength: maxMessageLength,
                              commands: commands.map({ $0.asCommand }),
                              created: created,
                              updated: updated)
    }
    
    required init() {
        super.init()
    }
    
    public init(config: Channel.Config) {
        reactionsEnabled = config.reactionsEnabled
        typingEventsEnabled = config.typingEventsEnabled
        readEventsEnabled = config.readEventsEnabled
        connectEventsEnabled = config.connectEventsEnabled
        uploadsEnabled = config.uploadsEnabled
        repliesEnabled = config.repliesEnabled
        searchEnabled = config.searchEnabled
        mutesEnabled = config.mutesEnabled
        urlEnrichmentEnabled = config.urlEnrichmentEnabled
        flagsEnabled = config.flagsEnabled
        messageRetention = config.messageRetention
        maxMessageLength = config.maxMessageLength
        created = config.created
        updated = config.updated
        commands.append(objectsIn: config.commands.map({ ChannelCommandRealmObject(command: $0) }))
    }
}

// MARK: Command

public final class ChannelCommandRealmObject: Object {
    @objc dynamic var name = ""
    @objc dynamic var desc = ""
    @objc dynamic var set = ""
    @objc dynamic var args = ""
    
    override public static func primaryKey() -> String? {
        return "name"
    }
    
    public var asCommand: Channel.Command {
        return Channel.Command(name: name,
                               description: desc,
                               set: set,
                               args: args)
    }
    
    required init() {
        super.init()
    }
    
    public init(command: Channel.Command) {
        name = command.name
        desc = command.description
        set = command.set
        args = command.args
    }
}
