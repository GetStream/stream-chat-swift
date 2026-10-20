//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ScheduledMessageDTO)
class ScheduledMessageDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var cid: String
    @NSManaged var status: String
    @NSManaged var failureReason: String?
    @NSManaged var scheduledAt: DBDate
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate

    // A helper property used for sorting the pending messages before the failed ones.
    @NSManaged var isPending: Bool

    // The content of the message that will be sent.
    @NSManaged var text: String
    @NSManaged var attachments: Data?
    @NSManaged var extraData: Data?
    @NSManaged var mentionedUserIds: [String]?
    @NSManaged var mentionedRoles: [String]?
    @NSManaged var mentionedHere: Bool
    @NSManaged var mentionedChannel: Bool
    @NSManaged var parentMessageId: String?
    @NSManaged var showReplyInChannel: Bool
    @NSManaged var quotedMessageId: String?
    @NSManaged var pollId: String?
    @NSManaged var isSilent: Bool
    @NSManaged var isPinned: Bool
    @NSManaged var pinExpires: DBDate?

    // The backend only returns the channel in query results, so the last known one is kept.
    @NSManaged var channelName: String?
    @NSManaged var channelImageURL: URL?

    // Relationships
    @NSManaged var user: UserDTO?

    override func willSave() {
        super.willSave()

        let newIsPending = ScheduledMessageStatus(rawValue: status) != .failed
        if isPending != newIsPending {
            isPending = newIsPending
        }
    }

    /// Returns a fetch request for the scheduled message with the provided id.
    static func fetchRequest(id: String) -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: true)]
        return request
    }

    /// Returns a fetch request for scheduled messages based on the provided query.
    static func scheduledMessagesFetchRequest(query: ScheduledMessageListQuery) -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        ScheduledMessageDTO.applyPrefetchingState(to: request)

        var sortDescriptors: [NSSortDescriptor] = []
        for sorting in query.sort {
            switch sorting.key {
            case .scheduledAt:
                sortDescriptors.append(NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: sorting.isAscending))
            case .createdAt:
                sortDescriptors.append(NSSortDescriptor(keyPath: \ScheduledMessageDTO.createdAt, ascending: sorting.isAscending))
            default:
                continue
            }
        }
        // Without a sorting, pending messages come first and failed ones after, each sorted by `scheduledAt`.
        if sortDescriptors.isEmpty {
            sortDescriptors = [
                NSSortDescriptor(keyPath: \ScheduledMessageDTO.isPending, ascending: false),
                NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: true)
            ]
        }
        request.sortDescriptors = sortDescriptors

        if let filter = query.filter, let predicate = filter.predicate {
            request.predicate = predicate
        }

        return request
    }

    /// Loads the scheduled message with the specified id.
    static func load(id: String, context: NSManagedObjectContext) -> ScheduledMessageDTO? {
        load(by: fetchRequest(id: id), context: context).first
    }

    /// Loads or creates the scheduled message with the specified id.
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> ScheduledMessageDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        return new
    }
}

extension NSManagedObjectContext: ScheduledMessageDatabaseSession {
    func saveScheduledMessage(payload: ScheduledMessageResponse) throws -> ScheduledMessageDTO {
        let cid = try ChannelId(cid: payload.cid)
        let dto = ScheduledMessageDTO.loadOrCreate(id: payload.id, context: self)

        dto.cid = cid.rawValue
        dto.status = payload.status
        dto.failureReason = payload.failureReason
        dto.scheduledAt = payload.scheduledAt.bridgeDate
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.user = try saveUser(payload: payload.user)

        let message = payload.message
        dto.text = message.text
        dto.attachments = try message.attachments.map { try JSONEncoder.default.encode($0) }
        dto.extraData = try JSONEncoder.default.encode(message.custom)
        dto.mentionedUserIds = message.mentionedUsers ?? []
        dto.mentionedRoles = message.mentionedRoles ?? []
        dto.mentionedHere = message.mentionedHere ?? false
        dto.mentionedChannel = message.mentionedChannel ?? false
        dto.parentMessageId = message.parentId
        dto.showReplyInChannel = message.showInChannel ?? false
        dto.quotedMessageId = message.quotedMessageId
        dto.pollId = message.pollId
        dto.isSilent = message.silent ?? false
        dto.isPinned = message.pinned ?? false
        dto.pinExpires = message.pinExpires?.bridgeDate

        if let channel = payload.channel {
            dto.channelName = channel.name
            dto.channelImageURL = channel.image.flatMap(URL.init(string:))
        }

        return dto
    }

    func scheduledMessage(id: String) -> ScheduledMessageDTO? {
        ScheduledMessageDTO.load(id: id, context: self)
    }

    func deleteScheduledMessage(id: String) {
        guard let dto = scheduledMessage(id: id) else { return }
        delete(dto)
    }
}

// MARK: - Converting to domain model

extension ScheduledMessageDTO {
    /// Snapshots the current state of `ScheduledMessageDTO` and returns an immutable model object from it.
    ///
    /// The backend returns the user ids of the mentions, the id of the quoted message and the id of the poll,
    /// so they are resolved from the database when they are available there.
    /// It does not fail for a deleted scheduled message, so its removal can be reported, but the related objects
    /// are not resolved from the database then.
    func asModel() throws -> ScheduledMessage {
        if let user {
            return try asModel(author: user.asModel())
        }
        // The relationships of a deleted scheduled message are cleared, but its removal is still reported.
        guard isDeleted || managedObjectContext == nil else {
            throw InvalidModel(self)
        }
        return try asModel(author: .placeholder(id: ""))
    }

    private func asModel(author: ChatUser) throws -> ScheduledMessage {
        let context = managedObjectContext
        let channelId = try ChannelId(cid: cid)
        let mentionedUsers = Set((mentionedUserIds ?? []).map { userId in
            context?.user(id: userId).flatMap { try? $0.asModel() } ?? .placeholder(id: userId)
        })
        let quotedMessage = quotedMessageId.flatMap { context?.message(id: $0) }.flatMap { try? $0.asModel() }
        let poll = pollId.flatMap { try? context?.poll(id: $0) }.flatMap { try? $0.asModel() }
        let attachmentPayloads = try attachments.map {
            try JSONDecoder.default.decode([MessageAttachmentPayload].self, from: $0)
        } ?? []
        let attachments = attachmentPayloads.enumerated().map { index, attachment in
            AnyChatMessageAttachment(
                id: AttachmentId(cid: channelId, messageId: id, index: index),
                type: attachment.attachmentType,
                payload: (try? JSONEncoder.default.encode(attachment.payload)) ?? Data(),
                downloadingState: nil,
                uploadingState: nil
            )
        }
        let extraData = try extraData.map { try JSONDecoder.default.decode([String: RawJSON].self, from: $0) } ?? [:]
        let scheduledAt = scheduledAt.bridgeDate

        let chatMessage = ChatMessage(
            id: id,
            cid: channelId,
            text: text,
            type: parentMessageId == nil ? .regular : .reply,
            command: nil,
            createdAt: scheduledAt,
            locallyCreatedAt: nil,
            updatedAt: updatedAt.bridgeDate,
            deletedAt: nil,
            arguments: nil,
            parentMessageId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            replyCount: 0,
            extraData: extraData,
            quotedMessage: quotedMessage,
            isBounced: false,
            isSilent: isSilent,
            isShadowed: false,
            deletedForMe: false,
            reactionScores: [:],
            reactionCounts: [:],
            reactionGroups: [:],
            author: author,
            mentionedUsers: mentionedUsers,
            mentionedHere: mentionedHere,
            mentionedChannel: mentionedChannel,
            mentionedRoles: mentionedRoles ?? [],
            threadParticipants: [],
            attachments: attachments,
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: [],
            currentUserReactions: [],
            isSentByCurrentUser: true,
            pinDetails: isPinned ? MessagePinDetails(
                pinnedAt: scheduledAt,
                pinnedBy: author,
                expiresAt: pinExpires?.bridgeDate
            ) : nil,
            translations: nil,
            originalLanguage: nil,
            moderationDetails: nil,
            readBy: [],
            poll: poll,
            textUpdatedAt: nil,
            draftReply: nil,
            reminder: nil,
            sharedLocation: nil
        )

        let localChannel = channelName == nil && channelImageURL == nil ? context?.channel(cid: channelId) : nil
        return ScheduledMessage(
            id: id,
            cid: channelId,
            channel: ScheduledMessageChannel(
                cid: channelId,
                name: channelName ?? localChannel?.name,
                imageURL: channelImageURL ?? localChannel?.imageURL
            ),
            message: chatMessage,
            quotedMessageId: quotedMessageId,
            scheduledAt: scheduledAt,
            status: ScheduledMessageStatus(rawValue: status),
            failureReason: failureReason.map(ScheduledMessageFailureReason.init(rawValue:)),
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt.bridgeDate
        )
    }
}

private extension ChatUser {
    static func placeholder(id: UserId) -> ChatUser {
        ChatUser(
            id: id,
            name: nil,
            imageURL: nil,
            isOnline: false,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            teams: [],
            language: nil,
            avgResponseTime: nil,
            extraData: [:]
        )
    }
}
