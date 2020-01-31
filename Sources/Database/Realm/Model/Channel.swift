//
//  Channel.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 19/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class Channel: Object {
    
    @objc dynamic var cid = ""
    @objc dynamic var id = ""
    @objc dynamic var type = ""
    @objc dynamic var name = ""
    @objc dynamic var imageURL: String?
    @objc dynamic var lastMessageDate: Date?
    @objc dynamic var created = Date.default
    @objc dynamic var deleted: Date?
    @objc dynamic var createdBy: User?
    @objc dynamic var frozen = false
    @objc dynamic var config: ChannelConfig?
    @objc dynamic var extraData: Data?
    let members = List<Member>()
    
    override public static func primaryKey() -> String? {
        return "cid"
    }
    
    override public class func indexedProperties() -> [String] {
        return indexedPropertiesKeyPaths([\Channel.id, \Channel.type, \Channel.created])
    }
    
    public var asChannel: StreamChatCore.Channel? {
        return StreamChatCore.Channel(type: ChannelType(rawValue: type),
                                      id: id,
                                      name: name,
                                      imageURL: imageURL?.url,
                                      lastMessageDate: lastMessageDate,
                                      created: created,
                                      deleted: deleted,
                                      createdBy: createdBy?.asUser,
                                      frozen: frozen,
                                      members: members.compactMap({ $0.asMember }),
                                      config: config?.asConfig ?? StreamChatCore.Channel.Config(),
                                      extraData: ExtraData.ChannelWrapper.decode(extraData))
    }
    
    required init() {
        super.init()
    }
    
    public init(_ channel: StreamChatCore.Channel) {
        cid = channel.cid.description
        id = channel.id
        type = channel.type.rawValue
        name = channel.name
        imageURL = channel.imageURL?.absoluteString
        lastMessageDate = channel.lastMessageDate
        created = channel.created
        deleted = channel.deleted
        frozen = channel.frozen
        config = channel.config.isEmpty ? nil : ChannelConfig(config: channel.config)
        extraData = channel.extraData?.encode()
        members.append(objectsIn: channel.members.map({ Member(member: $0, channel: channel) }))
        
        if let createdBy = channel.createdBy {
            self.createdBy = User(createdBy)
        }
    }
}

// MARK: - Config

public final class ChannelConfig: Object {
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
    let commands = List<ChannelCommand>()
    
    public var asConfig: StreamChatCore.Channel.Config {
        return StreamChatCore.Channel.Config(reactionsEnabled: reactionsEnabled,
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
    
    public init(config: StreamChatCore.Channel.Config) {
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
        commands.append(objectsIn: config.commands.map({ ChannelCommand(command: $0) }))
    }
}

// MARK: Command

public final class ChannelCommand: Object {
    @objc dynamic var name = ""
    @objc dynamic var desc = ""
    @objc dynamic var set = ""
    @objc dynamic var args = ""
    
    override public static func primaryKey() -> String? {
        return "name"
    }
    
    public var asCommand: StreamChatCore.Channel.Command {
        return StreamChatCore.Channel.Command(name: name,
                                              description: desc,
                                              set: set,
                                              args: args)
    }
    
    required init() {
        super.init()
    }
    
    public init(command: StreamChatCore.Channel.Command) {
        name = command.name
        desc = command.description
        set = command.set
        args = command.args
    }
}
