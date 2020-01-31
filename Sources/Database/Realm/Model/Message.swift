//
//  Message.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 27/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class Message: Object {
    
    @objc dynamic var channel: Channel?
    @objc dynamic var id = ""
    @objc dynamic var type = ""
    @objc dynamic var user: User?
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
    let attachments = List<Attachment>()
    let mentionedUsers = List<User>()
    let latestReactions = List<Reaction>()
    let ownReactions = List<Reaction>()
    let reactionCounts = List<ReactionCounts>()
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public class func indexedProperties() -> [String] {
        return indexedPropertiesKeyPaths([\Message.created])
    }
    
    var asMessage: StreamChatCore.Message? {
        guard let type = StreamChatCore.MessageType(rawValue: type), let user = user?.asUser else {
            return nil
        }
        
        var messageReactionCounts = [StreamChatCore.ReactionType: Int]()
        
        reactionCounts.forEach { realmObject in
            if let type = StreamChatCore.ReactionType(rawValue: realmObject.type) {
                messageReactionCounts[type] = realmObject.count
            }
        }
        
        let reactionCounts = messageReactionCounts.isEmpty ? nil : StreamChatCore.ReactionCounts(counts: messageReactionCounts)
        
        return StreamChatCore.Message(id: id,
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
                                      reactionCounts: reactionCounts,
                                      replyCount: replyCount,
                                      showReplyInChannel: showReplyInChannel)
    }
    
    required init() {
        super.init()
    }
    
    init(_ message: StreamChatCore.Message, channelRealmObject: Channel) {
        channel = channelRealmObject
        id = message.id
        type = message.type.rawValue
        parentId = message.parentId
        created = message.created
        updated = message.updated
        deleted = message.deleted
        text = message.text
        command = message.command
        args = message.args
        user = User(message.user)
        attachments.append(objectsIn: message.attachments.map({ Attachment($0) }))
        mentionedUsers.append(objectsIn: message.mentionedUsers.map({ User($0) }))
        extraData = message.extraData?.encode()
        latestReactions.append(objectsIn: message.latestReactions.map({ Reaction($0) }))
        ownReactions.append(objectsIn: message.ownReactions.map({ Reaction($0) }))
        
        if let reactionCounts = message.reactionCounts?.counts {
            let reactionCountReamObjects = reactionCounts.compactMap({ ReactionCounts(type: $0.key.rawValue,
                                                                                      count: $0.value) })
            self.reactionCounts.append(objectsIn: reactionCountReamObjects)
        }
    }
}
