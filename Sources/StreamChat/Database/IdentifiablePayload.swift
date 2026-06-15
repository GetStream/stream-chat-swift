//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
                case ThreadDTO.className:
                    return ThreadDTO.self
                case ThreadParticipantDTO.className:
                    return ThreadParticipantDTO.self
                case ThreadReadDTO.className:
                    return ThreadReadDTO.self
                case CurrentUserDTO.className:
                    return CurrentUserDTO.self
                case DeviceDTO.className:
                    return DeviceDTO.self
                case MessageReminderDTO.className:
                    return MessageReminderDTO.self
                case PollDTO.className:
                    return PollDTO.self
                case PollOptionDTO.className:
                    return PollOptionDTO.self
                case PollVoteDTO.className:
                    return PollVoteDTO.self
                case SharedLocationDTO.className:
                    return SharedLocationDTO.self
                default:
                    return nil
                }
            }()

            guard let modelClass = modelClass, let keyPath = modelClass.idKeyPath else { continue }

            let values = Array(identifiableValues)
            nonisolated(unsafe) var modelMapping: [DatabaseId: NSManagedObjectID] = [:]
            context.performAndWait {
                let results = modelClass.batchFetch(keyPath: keyPath, equalTo: values, context: context)
                results.forEach {
                    if let id = modelClass.id(for: $0) {
                        modelMapping[id] = $0.objectID
                    }
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

extension Array: IdentifiablePayload where Element: IdentifiablePayload {
    var databaseId: DatabaseId? { nil }
    static var modelClass: (IdentifiableDatabaseObject).Type? { nil }

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        forEach {
            $0.fillIds(cache: &cache)
        }
    }
}

extension QueryUsersResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        users.fillIds(cache: &cache)
    }
}

extension GetReactionsResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        reactions.fillIds(cache: &cache)
    }
}

extension SearchResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        // TODO: map SearchResult.message to MessageResponse and cache
    }
}

extension MembersResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        members.fillIds(cache: &cache)
    }
}

extension QueryChannelsResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        channels.fillIds(cache: &cache)
    }
}

extension ChannelStateResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        channel?.fillIds(cache: &cache)
        watchers?.fillIds(cache: &cache)
        membership?.fillIds(cache: &cache)
        messages.fillIds(cache: &cache)
        pinnedMessages.fillIds(cache: &cache)
        (read ?? []).fillIds(cache: &cache)
    }
}

extension ChannelResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { cid }
    static let modelClass: (IdentifiableDatabaseObject).Type? = ChannelDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        createdBy?.fillIds(cache: &cache)
        members?.fillIds(cache: &cache)
    }
}

extension QueryThreadsResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        threads.fillIds(cache: &cache)
    }
}

extension ThreadStateResponse: IdentifiablePayloadProxy {
    var databaseId: DatabaseId? { parentMessageId }
    static let modelClass: (IdentifiableDatabaseObject).Type? = ThreadDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        parentMessage?.fillIds(cache: &cache)
        channel?.fillIds(cache: &cache)
        createdBy?.fillIds(cache: &cache)
        latestReplies.fillIds(cache: &cache)
        (threadParticipants ?? []).fillIds(cache: &cache)
        (read ?? []).fillIds(cache: &cache)
    }
}

extension ThreadParticipantPayload: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension UserResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = UserDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
    }
}

extension MessageResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user.fillIds(cache: &cache)
        quotedMessage?.fillIds(cache: &cache)
        mentionedUsers.fillIds(cache: &cache)
        threadParticipants?.fillIds(cache: &cache)
        latestReactions.fillIds(cache: &cache)
        ownReactions.fillIds(cache: &cache)
        pinnedBy?.fillIds(cache: &cache)
    }
}

extension ReactionResponse: IdentifiablePayload {
    var databaseId: DatabaseId? {
        MessageReactionDTO.createId(userId: user.id, messageId: messageId, type: MessageReactionType(rawValue: type))
    }

    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageReactionDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user.fillIds(cache: &cache)
    }
}

extension ChannelMemberResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { nil } // Cannot build id without channel id
    static let modelClass: (IdentifiableDatabaseObject).Type? = MemberDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension ReadStateResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { nil } // Needs a composed predicate 'channel.cid == %@ && user.id == %@'
    static let modelClass: (IdentifiableDatabaseObject).Type? = ChannelReadDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user.fillIds(cache: &cache)
    }
}

extension OwnUserResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = CurrentUserDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        channelMutes.fillIds(cache: &cache)
        devices.fillIds(cache: &cache)
        mutes.fillIds(cache: &cache)
    }
}

extension DeviceResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = DeviceDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
    }
}

extension UserMuteResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        target?.fillIds(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension ChannelMute: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        channel?.fillIds(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension DraftResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        channel?.fillIds(cache: &cache)
        message.fillIds(cache: &cache)
        parentMessage?.fillIds(cache: &cache)
        quotedMessage?.fillIds(cache: &cache)
    }
}

extension DraftPayloadResponse: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        mentionedUsers?.fillIds(cache: &cache)
    }
}

extension ReminderResponseData: IdentifiablePayload {
    var databaseId: DatabaseId? { messageId }
    static let modelClass: (IdentifiableDatabaseObject).Type? = MessageReminderDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        channel?.fillIds(cache: &cache)
        message?.fillIds(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension SharedLocationResponseData: IdentifiablePayload {
    var databaseId: DatabaseId? { messageId }
    static let modelClass: (IdentifiableDatabaseObject).Type? = SharedLocationDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        channel?.fillIds(cache: &cache)
        message?.fillIds(cache: &cache)
    }
}

extension PollResponseData: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = PollDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        createdBy?.fillIds(cache: &cache)
        options.fillIds(cache: &cache)
        latestAnswers.fillIds(cache: &cache)
        ownVotes.fillIds(cache: &cache)
        latestVotesByOption.values.forEach { $0.fillIds(cache: &cache) }
    }
}

extension PollOptionResponseData: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = PollOptionDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
    }
}

extension PollVoteResponseData: IdentifiablePayload {
    var databaseId: DatabaseId? { id }
    static let modelClass: (IdentifiableDatabaseObject).Type? = PollVoteDTO.self

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        addId(cache: &cache)
        user?.fillIds(cache: &cache)
    }
}

extension PollVotesResponse: IdentifiablePayloadProxy {
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        votes.fillIds(cache: &cache)
    }
}

private extension NSManagedObject {
    static func batchFetch(keyPath: String, equalTo values: [String], context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K IN %@", keyPath, values)
        return load(by: request, context: context)
    }
}
