//
//  ChannelRealmObject.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 19/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatCore
import RealmSwift

public final class ChannelRealmObject: Object {
    
    @objc dynamic var id: String = ""
    @objc dynamic var type: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var imageURL: URL?
    @objc dynamic var lastMessageDate: Date?
    @objc dynamic var created: Date = Date()
    @objc dynamic var deleted: Date?
    @objc dynamic var createdBy: UserRealmObject = UserRealmObject()
    @objc dynamic var config: ConfigRealmObject = ConfigRealmObject()
    @objc dynamic var extraData: Data?
    let members = List<MemberRealmObject>()
    
    public var asChannel: Channel? {
        return Channel(type: ChannelType(rawValue: type),
                       id: id,
                       name: name,
                       imageURL: imageURL,
                       members: members.compactMap({ $0.asMember }),
                       extraData: ExtraData.ChannelWrapper.decode(extraData))
    }
    
    required init() {}
    
    public init(_ channel: Channel) {
        id = channel.id
        type = channel.type.rawValue
        name = channel.name
        imageURL = channel.imageURL
        lastMessageDate = channel.lastMessageDate
        created = channel.created
        deleted = channel.deleted
        extraData = channel.extraData?.encode()
    }
}

extension ChannelRealmObject {
    public final class ConfigRealmObject: Object {
        
    }
}
