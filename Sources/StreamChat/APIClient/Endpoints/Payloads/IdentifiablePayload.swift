//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

protocol IdentifiablePayload {
    var databaseId: DatabaseId? { get }
    static var modelClass: (IdentifiableDatabaseObject).Type? { get }
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>])
}

extension IdentifiablePayload {
    func addId(cache: inout [String: Set<String>]) {
        guard let databaseId = databaseId, let modelClassName = Self.modelClass?.className else { return }
        var ids = (cache[modelClassName] ?? Set<String>())
        ids.insert(databaseId)
        cache[modelClassName] = ids
    }

    func recursivelyGetAllIds() -> [String: Set<String>] {
        var cache: [String: Set<String>] = [:]
        fillIds(cache: &cache)
        return cache
    }

    func getPayloadToModelIdMappings(context: NSManagedObjectContext) -> PreWarmedCache {
        let payloadIdsMappings = recursivelyGetAllIds()
        var cache: PreWarmedCache = [:]

        for (className, identifiableValues) in payloadIdsMappings {
            let modelClass: (IdentifiableDatabaseObject).Type? = {
                switch className {
                case ChannelDTO.className:
                    return ChannelDTO.self
                case UserDTO.className:
                    return UserDTO.self
                case MessageDTO.className:
                    return MessageDTO.self
                case MessageReactionDTO.className:
                    return MessageReactionDTO.self
                case MemberDTO.className:
                    return MemberDTO.self
                case ChannelReadDTO.className:
                    return ChannelReadDTO.self
                default:
                    return nil
                }
            }()

            guard let modelClass = modelClass, let keyPath = modelClass.idKeyPath else { continue }

            let values = Array(identifiableValues)
            var results: [NSManagedObject]?
            context.performAndWait {
                results = modelClass.batchFetch(keyPath: keyPath, equalTo: values, context: context)
            }
            guard let results = results else { continue }

            var modelMapping: [DatabaseId: NSManagedObjectID] = [:]
            results.forEach {
                if let id = modelClass.id(for: $0) {
                    modelMapping[id] = $0.objectID
                }
            }
            cache[modelClass.className] = modelMapping
        }

        return cache
    }
}

protocol IdentifiablePayloadProxy: IdentifiablePayload {}

extension IdentifiablePayloadProxy {
    var databaseId: DatabaseId? { nil }
    static var modelClass: (IdentifiableDatabaseObject).Type? { nil }
}

extension Array where Element: IdentifiablePayload {
    var databaseId: DatabaseId? { nil }
    static var modelClass: (IdentifiableDatabaseObject).Type? { nil }

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        forEach {
            $0.fillIds(cache: &cache)
        }
    }
}

extension UserListPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        users.fillIds(cache: &cache)
    }
}

extension MessageListPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        messages.fillIds(cache: &cache)
    }
}

extension MessageReactionsPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        reactions.fillIds(cache: &cache)
    }
}

extension MessageSearchResultsPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        results.fillIds(cache: &cache)
    }
}

extension MessagePayload.Boxed: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        message.fillIds(cache: &cache)
    }
}

extension ChannelMemberListPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        members.fillIds(cache: &cache)
    }
}

extension ChannelListPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        channels.fillIds(cache: &cache)
    }
}

extension ChannelPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        channel.fillIds(cache: &cache)
        watchers?.fillIds(cache: &cache)
        membership?.fillIds(cache: &cache)
        messages.fillIds(cache: &cache)
        pinnedMessages.fillIds(cache: &cache)
        channelReads.fillIds(cache: &cache)
    }
}

extension ChannelDetailPayload: IdentifiablePayload {
    var databaseId: DatabaseId? { cid.rawValue }
    static let modelClass: (IdentifiableDatabaseObject).Type? = ChannelDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        createdBy?.fillIds(cache: &cache)
        members?.fillIds(cache: &cache)
        invitedMembers.fillIds(cache: &cache)
    }
}

extension UserPayload: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = UserDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
    }
}

extension MessagePayload: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user.fillIds(cache: &cache)
        quotedMessage?.fillIds(cache: &cache)
        mentionedUsers.fillIds(cache: &cache)
        threadParticipants.fillIds(cache: &cache)
        latestReactions.fillIds(cache: &cache)
        ownReactions.fillIds(cache: &cache)
        pinnedBy?.fillIds(cache: &cache)
        pinnedBy?.fillIds(cache: &cache)
    }
}

extension MessageReactionPayload: IdentifiablePayload {
    var databaseId: DatabaseId? {
        MessageReactionDTO.createId(userId: user.id, messageId: messageId, type: type)
    }

    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageReactionDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user.fillIds(cache: &cache)
    }
}

extension MemberPayload: IdentifiablePayload {
    var databaseId: DatabaseId? { nil } // Cannot build id without channel id
    static let modelClass: (IdentifiableDatabaseObject).Type? = MemberDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user.fillIds(cache: &cache)
    }
}

extension ChannelReadPayload: IdentifiablePayload {
    var databaseId: DatabaseId? { nil } // Needs a composed predicate 'channel.cid == %@ && user.id == %@'
    static let modelClass: (IdentifiableDatabaseObject).Type? = ChannelReadDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user.fillIds(cache: &cache)
    }
}

private extension NSManagedObject {
    static func batchFetch(keyPath: String, equalTo values: [String], context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K IN %@", keyPath, values)
        return load(by: request, context: context)
    }
}
