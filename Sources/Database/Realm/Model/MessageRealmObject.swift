//
//  MessageRealmObject.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 27/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class MessageRealmObject: Object, RealmObjectIndexable {
    
    @objc dynamic var id = ""
    @objc dynamic var type = ""
    @objc dynamic var user = UserRealmObject()
    @objc dynamic var created = Date.default
    @objc dynamic var updated = Date.default
    @objc dynamic var deleted: Date?
    @objc dynamic var text = ""
    @objc dynamic var command: String?
    @objc dynamic var args: String?
    @objc dynamic var parentId: String?
    @objc dynamic var showReplyInChannel = false
    @objc dynamic var replyCount = 0
    @objc dynamic var extraData: Data?
    let attachments = List<AttachmentRealmObject>()
    let mentionedUsers = List<UserRealmObject>()
    let latestReactions = List<ReactionRealmObject>()
    let ownReactions = List<ReactionRealmObject>()
    let reactionCounts = List<ReactionCountsRealmObject>()
    
    public static var indexedPropertiesKeyPaths: [AnyKeyPath] = [\MessageRealmObject.created]
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    var asMessage: Message? {
        guard let type = MessageType(rawValue: type), let user = user.asUser else {
            return nil
        }
        
        var messageReactionCounts = [ReactionType: Int]()
        
        reactionCounts.forEach { realmObject in
            if let type = ReactionType(rawValue: realmObject.type) {
                messageReactionCounts[type] = realmObject.count
            }
        }
        
        return Message(id: id,
                       type: type,
                       parentId: parentId,
                       created: created,
                       updated: updated,
                       deleted: deleted,
                       text: text,
                       command: command,
                       args: args,
                       user: user,
                       attachments: attachments.map({ $0.asAttachment }),
                       mentionedUsers: mentionedUsers.compactMap({ $0.asUser }),
                       extraData: ExtraData.UserWrapper.decode(extraData),
                       latestReactions: latestReactions.compactMap({ $0.asReaction }),
                       ownReactions: ownReactions.compactMap({ $0.asReaction }),
                       reactionCounts: messageReactionCounts.isEmpty ? nil : ReactionCounts(counts: messageReactionCounts),
                       replyCount: replyCount,
                       showReplyInChannel: showReplyInChannel)
    }
    
    required init() {}
    
    init(_ message: Message) {
        id = message.id
        type = message.type.rawValue
        parentId = message.parentId
        created = message.created
        updated = message.updated
        deleted = message.deleted
        text = message.text
        command = message.command
        args = message.args
        user = UserRealmObject(message.user)
        attachments.append(objectsIn: message.attachments.map({ AttachmentRealmObject($0) }))
        mentionedUsers.append(objectsIn: message.mentionedUsers.map({ UserRealmObject($0) }))
        extraData = message.extraData?.encode()
        latestReactions.append(objectsIn: message.latestReactions.map({ ReactionRealmObject($0) }))
        ownReactions.append(objectsIn: message.ownReactions.map({ ReactionRealmObject($0) }))
        
        if let reactionCounts = message.reactionCounts?.counts {
            let reactionCountReamObjects = reactionCounts.compactMap({ ReactionCountsRealmObject(type: $0.key.rawValue,
                                                                                                 count: $0.value) })
            self.reactionCounts.append(objectsIn: reactionCountReamObjects)
        }
    }
}
