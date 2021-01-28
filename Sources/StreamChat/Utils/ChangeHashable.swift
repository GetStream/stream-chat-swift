//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// **The problem we're trying to solve with the types in this file**
/// CoreData unnecessarily generates an `update` notification for entities when the same value is assigned.
/// Let's say we have a CoreData entity with `value` set to 1. If we do:
/// `dto.value = 1` to assign the same value, CoreData generates an update notification.
/// This causes unnecessary noise in our Controller's delegate methods and logs, and possible performance issues.
/// We use the types in this file to create our own "change hash" for entities to compare during `save` calls
/// so we don't do unnecessary saves.
///
/// We don't use `Hashable` protocol since we don't hash all the properties, since not all properties of a payload/DTO can be
/// included in the hash properly. (Also sometimes missing properties, and having the same payload coming from multiple events)
///
/// Please check CIS-582 for more info.

// MARK: - ChangeHasher and implementations

/// Underlying protocol for custom Hashers.
///
/// We use this type to create entity hashers that we make sure all changeable properties are included in the hash.
/// In case the payload's `changeHash` and saved `DTO`s `changeHash` is the same,
/// the properties included in the hash are not updated to DB when an update from backend comes.
///
/// Moreover, the custom entity hashers' initializers warn us when we decide a new property should affect the hash but
/// we forgot to include it in the `changeHash`
protocol ChangeHasher {
    /// Hash of the properties the entity changes between updates.
    var changeHash: Int { get }
}

/// Custom hasher for User entity.
struct UserHasher: ChangeHasher {
    let id: String
    let name: String?
    let imageURL: URL?
    let role: String
    let createdAt: Date
    let updatedAt: Date
    let lastActiveAt: Date?
    let isOnline: Bool
    // let isInvisible: Bool
    let isBanned: Bool
    // let teams: [String]
    let extraData: Data
    
    var changeHash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(imageURL)
        hasher.combine(role)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
        hasher.combine(lastActiveAt)
        hasher.combine(isOnline)
        // hasher.combine(isInvisible)
        hasher.combine(isBanned)
        // hasher.combine(teams)
        hasher.combine(extraData)
        return hasher.finalize()
    }
}

/// Custom hasher for Channel entity.
struct ChannelHasher: ChangeHasher {
    let cid: String
    let name: String?
    let imageURL: URL?
    let extraData: Data
    let typeRawValue: String
    let lastMessageAt: Date?
    let createdAt: Date
    let deletedAt: Date?
    let updatedAt: Date
    let createdByChangeHash: Int?
    let config: Data
    let isFrozen: Bool
    // let members: [MemberPayload<ExtraData.User>]?
    let memberCount: Int
    // let invitedMembers: [MemberPayload<ExtraData.User>] = [] // TODO?
    // let team: String
    
    var changeHash: Int {
        var hasher = Hasher()
        hasher.combine(cid)
        hasher.combine(name)
        hasher.combine(imageURL)
        hasher.combine(extraData)
        hasher.combine(typeRawValue)
        hasher.combine(config)
        hasher.combine(createdAt)
        hasher.combine(deletedAt)
        hasher.combine(updatedAt)
        hasher.combine(lastMessageAt)
        hasher.combine(memberCount)
        hasher.combine(isFrozen)
        hasher.combine(createdByChangeHash)
        return hasher.finalize()
    }
}

/// Custom hasher for Message entity.
struct MessageHasher: ChangeHasher {
    let id: String
    let type: String
    let userChangeHash: Int
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let quotedMessageChangeHash: Int?
    let mentionedUserChangeHashes: [Int]
    let threadParticipantChangeHashes: [Int]
    let replyCount: Int
    let extraData: Data
    let reactionScores: [String: Int]
    // let attachments: [AttachmentPayload<ExtraData.Attachment>]
    let isSilent: Bool
    
    var changeHash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
        hasher.combine(deletedAt)
        hasher.combine(type)
        hasher.combine(command)
        hasher.combine(args)
        hasher.combine(parentId)
        hasher.combine(showReplyInChannel)
        hasher.combine(replyCount)
        hasher.combine(extraData)
        hasher.combine(isSilent)
        hasher.combine(quotedMessageChangeHash)
        hasher.combine(userChangeHash)
        hasher.combine(reactionScores)
        for mentionedUserChangeHash in mentionedUserChangeHashes {
            hasher.combine(mentionedUserChangeHash)
        }
        for threadParticipantChangeHash in threadParticipantChangeHashes {
            hasher.combine(threadParticipantChangeHash)
        }
        return hasher.finalize()
    }
}

// MARK: - ChangeHashable

/// A type that can be hashed into a `ChangeHasher` to produce an integer hash value.
///
/// The type implementing this protocol needs to have their own `ChangeHasher` implementation nearly all the time.
/// (Example: UserPayload -> UserHasher)
/// It's enough that the type creates the necessary `hasher` and default implementation of `changeHash` will take care of the rest.
protocol ChangeHashable {
    /// ChangeHasher conformer for the type.
    var hasher: ChangeHasher { get }
    /// Change hash for the type.
    var changeHash: Int { get }
}

extension ChangeHashable {
    var changeHash: Int {
        hasher.changeHash
    }
}
