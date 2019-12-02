//
//  User.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 19/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class User: Object {
    
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var avatarURL: String?
    @objc dynamic var created = Date.default
    @objc dynamic var updated = Date.default
    @objc dynamic var lastActiveDate: Date?
    @objc dynamic var isInvisible: Bool = false
    @objc dynamic var isBanned: Bool = false
    @objc dynamic var role: String = "user"
    @objc dynamic var extraData: Data?
    let mutedUsers = List<MutedUser>()
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    public var asUser: StreamChatCore.User? {
        guard let role = StreamChatCore.User.Role(rawValue: role) else {
            return nil
        }
        
        return StreamChatCore.User(id: id,
                                   name: name,
                                   role: role,
                                   avatarURL: avatarURL?.url,
                                   created: created,
                                   updated: updated,
                                   lastActiveDate: lastActiveDate,
                                   isInvisible: isInvisible,
                                   isBanned: isBanned,
                                   mutedUsers: mutedUsers.compactMap({ $0.asMutedUser }),
                                   extraData: ExtraData.UserWrapper.decode(extraData))
    }
    
    required init() {}
    
    public init(_ user: StreamChatCore.User) {
        id = user.id
        name = user.name
        avatarURL = user.avatarURL?.absoluteString
        created = user.created
        updated = user.updated
        lastActiveDate = user.lastActiveDate
        isInvisible = user.isInvisible
        isBanned = user.isBanned
        role = user.role.rawValue
        extraData = user.extraData?.encode()
    }
}
