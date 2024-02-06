//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension StreamChatUsersResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        users.compactMap { $0 }.fillIds(cache: &cache)
    }
}

extension StreamChatChannelsResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        channels.fillIds(cache: &cache)
    }
}

extension StreamChatChannelStateResponseFields: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        channel?.fillIds(cache: &cache)
        watchers?.fillIds(cache: &cache)
        membership?.fillIds(cache: &cache)
        messages.fillIds(cache: &cache)
        pinnedMessages.fillIds(cache: &cache)
        read?.compactMap { $0 }.fillIds(cache: &cache)
    }
}

extension StreamChatChannelResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { cid }
    static let modelClass: (IdentifiableDatabaseObject).Type? = ChannelDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        createdBy?.fillIds(cache: &cache)
        members?.compactMap { $0 }.fillIds(cache: &cache)
//        invitedMembers.fillIds(cache: &cache) TODO: not in the response.
    }
}

extension StreamChatUserResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = UserDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
    }
}

extension StreamChatUserObject: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = UserDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
    }
}

extension StreamChatMessage: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user?.fillIds(cache: &cache)
        quotedMessage?.fillIds(cache: &cache)
        mentionedUsers.fillIds(cache: &cache)
        threadParticipants?.compactMap { $0 }.fillIds(cache: &cache)
        latestReactions.compactMap { $0 }.fillIds(cache: &cache)
        ownReactions.compactMap { $0 }.fillIds(cache: &cache)
        pinnedBy?.fillIds(cache: &cache)
        pinnedBy?.fillIds(cache: &cache)
    }
}

extension StreamChatReaction: IdentifiablePayload {
    var databaseId: DatabaseId? {
        if let userId = user?.id {
            return MessageReactionDTO.createId(
                userId: userId,
                messageId: messageId,
                type: MessageReactionType(rawValue: type)
            )
        } else {
            return nil
        }
    }

    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageReactionDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension StreamChatChannelMember: IdentifiablePayload {
    var databaseId: DatabaseId? { nil } // Cannot build id without channel id
    static let modelClass: (IdentifiableDatabaseObject).Type? = MemberDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension StreamChatRead: IdentifiablePayload {
    var databaseId: DatabaseId? { nil } // Needs a composed predicate 'channel.cid == %@ && user.id == %@'
    static let modelClass: (IdentifiableDatabaseObject).Type? = ChannelReadDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension StreamChatMembersResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        members.compactMap { $0 }.fillIds(cache: &cache)
    }
}

extension StreamChatGetRepliesResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        messages.fillIds(cache: &cache)
    }
}

extension StreamChatGetReactionsResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        reactions.compactMap { $0 }.fillIds(cache: &cache)
    }
}

extension StreamChatSearchResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        results.compactMap { $0 }.fillIds(cache: &cache)
    }
}

extension StreamChatSearchResult: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        message?.toMessage.fillIds(cache: &cache)
    }
}
