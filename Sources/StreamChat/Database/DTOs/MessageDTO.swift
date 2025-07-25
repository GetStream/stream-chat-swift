//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A reaction is represented by a String with the following format: "userId/messageId/reactionType"
typealias ReactionString = String
extension ReactionString {
    var reactionUserId: String {
        split(separator: "/").first.map(String.init) ?? ""
    }

    var reactionType: String {
        split(separator: "/").last.map(String.init) ?? ""
    }
}

@objc(MessageDTO)
class MessageDTO: NSManagedObject {
    @NSManaged fileprivate var localMessageStateRaw: String?

    @NSManaged var id: String
    @NSManaged var cid: String?
    @NSManaged var text: String
    @NSManaged var type: String
    @NSManaged var command: String?
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var deletedAt: DBDate?
    @NSManaged var textUpdatedAt: DBDate?
    @NSManaged var isHardDeleted: Bool
    @NSManaged var args: String?
    @NSManaged var parentMessageId: MessageId?
    @NSManaged var parentMessage: MessageDTO?
    @NSManaged var showReplyInChannel: Bool
    @NSManaged var replyCount: Int32
    @NSManaged var extraData: Data?
    @NSManaged var isSilent: Bool

    @NSManaged var skipPush: Bool
    @NSManaged var skipEnrichUrl: Bool
    @NSManaged var isShadowed: Bool
    @NSManaged var reactionScores: [String: Int]
    @NSManaged var reactionCounts: [String: Int]
    @NSManaged var reactionGroups: Set<MessageReactionGroupDTO>

    @NSManaged var latestReactions: [ReactionString]
    @NSManaged var ownReactions: [ReactionString]

    @NSManaged var translations: [String: String]?
    @NSManaged var originalLanguage: String?
    
    @NSManaged var moderationDetails: MessageModerationDetailsDTO?
    var isBounced: Bool {
        moderationDetails?.action == MessageModerationAction.bounce.rawValue
    }

    // Boolean flag that determines if the reply will be shown inside the thread query.
    // This boolean is used to control the pagination of the replies of a thread.
    @NSManaged var showInsideThread: Bool

    // Used for paginating newer replies while jumping to a mid-page.
    // We want to avoid new replies being inserted in the UI if we are in a mid-page.
    @NSManaged var newestReplyAt: DBDate?

    @NSManaged var user: UserDTO

    /// Use this property in case you want to read the mentioned users in the message.
    @NSManaged var mentionedUsers: Set<UserDTO>
    /// Use this property ONLY when creating/updating a message with new mentioned users.
    @NSManaged var mentionedUserIds: [String]

    @NSManaged var threadParticipants: NSOrderedSet
    @NSManaged var channel: ChannelDTO?
    @NSManaged var replies: Set<MessageDTO>
    @NSManaged var flaggedBy: CurrentUserDTO?
    @NSManaged var attachments: Set<AttachmentDTO>
    @NSManaged var poll: PollDTO?
    @NSManaged var quotedMessage: MessageDTO?
    @NSManaged var quotedBy: Set<MessageDTO>
    @NSManaged var searches: Set<MessageSearchQueryDTO>
    @NSManaged var previewOfChannel: ChannelDTO?

    @NSManaged var draftOfChannel: ChannelDTO?
    @NSManaged var draftOfThread: MessageDTO?
    @NSManaged var draftReply: MessageDTO?
    @NSManaged var isDraft: Bool

    @NSManaged var location: SharedLocationDTO?
    @NSManaged var isActiveLiveLocation: Bool
    
    @NSManaged var reminder: MessageReminderDTO?

    /// If the message is sent by the current user, this field
    /// contains channel reads of other channel members (excluding the current user),
    /// where `read.lastRead >= self.createdAt`.
    ///
    /// If the message has a channel read of a member, it is considered as seen/read by
    /// that member.
    ///
    /// For messages authored NOT by the current user this field is always empty.
    @NSManaged var reads: Set<ChannelReadDTO>
    
    @NSManaged var restrictedVisibility: Set<String>?

    @NSManaged var pinned: Bool
    @NSManaged var pinnedBy: UserDTO?
    @NSManaged var pinnedAt: DBDate?
    @NSManaged var pinExpires: DBDate?

    // The timestamp the message was created locally. Applies only for the messages of the current user.
    @NSManaged var locallyCreatedAt: DBDate?

    // We use `Date!` to replicate a required value. The value must be marked as optional in the CoreData model, because we change
    // it in the `willSave` phase, which happens after the validation.
    @NSManaged var defaultSortingKey: DBDate!

    override func willSave() {
        super.willSave()

        guard !isDeleted else {
            return
        }

        if let channel = channel, self.cid != channel.cid {
            self.cid = channel.cid
        }

        if let locationEndAt = location?.endAt?.bridgeDate {
            let isActiveLiveLocation = locationEndAt > Date()
            if isActiveLiveLocation != self.isActiveLiveLocation {
                self.isActiveLiveLocation = isActiveLiveLocation
            }
        }

        // Manually mark the channel as dirty to trigger the entity update and give the UI a chance
        // to reload the channel cell to reflect the updated preview.
        if let channel = previewOfChannel, !channel.hasChanges, !channel.isDeleted {
            let cid = channel.cid
            channel.cid = cid
        }

        // Refresh messages referencing the current message
        if !quotedBy.isEmpty {
            for message in quotedBy where !message.hasChanges && !message.isDeleted {
                let messageId = message.id
                message.id = messageId
            }
        }

        prepareDefaultSortKeyIfNeeded()
    }

    /// Makes sure the `defaultSortingKey` value is computed and set.
    fileprivate func prepareDefaultSortKeyIfNeeded() {
        let newSortingKey = locallyCreatedAt ?? createdAt
        if defaultSortingKey != newSortingKey {
            defaultSortingKey = newSortingKey
        }
    }

    /// Returns a fetch request for messages pending send.
    static func messagesPendingSendFetchRequest() -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.locallyCreatedAt, ascending: true)]

        let pendingSendMessage = NSPredicate(
            format: "localMessageStateRaw == %@", LocalMessageState.pendingSend.rawValue
        )
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            pendingSendMessage,
            allAttachmentsAreUploadedOrEmptyPredicate()
        ])

        return request
    }

    /// Returns a fetch request for messages pending sync.
    static func messagesPendingSyncFetchRequest() -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.locallyCreatedAt, ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "localMessageStateRaw == %@", LocalMessageState.pendingSync.rawValue),
            allAttachmentsAreUploadedOrEmptyPredicate()
        ])

        return request
    }

    /// Returns all the draft messages.
    static func draftMessagesFetchRequest(query: DraftListQuery) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = query.sorting.compactMap { $0.sortDescriptor() }
        let isPartOfChannelOrThreadPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "draftOfChannel != nil"),
            NSPredicate(format: "draftOfThread != nil")
        ])
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            isPartOfChannelOrThreadPredicate,
            NSPredicate(format: "isDraft == YES")
        ])
        return request
    }

    static func allAttachmentsAreUploadedOrEmptyPredicate() -> NSCompoundPredicate {
        NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(
                format: "SUBQUERY(attachments, $a, $a.localStateRaw == %@).@count == attachments.@count",
                LocalAttachmentState.uploaded.rawValue
            ),
            .init(format: "SUBQUERY(attachments, $a, $a.localStateRaw == nil).@count == attachments.@count")
        ])
    }

    /// Returns a predicate that filters out deleted message by other than the current user
    private static func onlyOwnDeletedMessagesPredicate() -> NSCompoundPredicate {
        .init(orPredicateWithSubpredicates: [
            // Non-deleted messages.
            nonDeletedMessagesPredicate(),
            // Deleted messages sent by current user excluding ephemeral ones.
            NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "deletedAt != nil"),
                .init(format: "user.currentUser != nil"),
                .init(format: "type != %@", MessageType.ephemeral.rawValue)
            ])
        ])
    }

    private static func deletedMessagesPredicate(
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility
    ) -> NSPredicate {
        let deletedMessagesPredicate: NSPredicate

        switch deletedMessagesVisibility {
        case .alwaysHidden:
            deletedMessagesPredicate = nonDeletedMessagesPredicate()
        case .visibleForCurrentUser:
            deletedMessagesPredicate = onlyOwnDeletedMessagesPredicate()
        case .alwaysVisible:
            deletedMessagesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                // Non-deleted messages
                nonDeletedMessagesPredicate(),
                // Deleted messages excluding ephemeral ones
                NSPredicate(format: "deletedAt != nil AND type != %@", MessageType.ephemeral.rawValue)
            ])
        }

        let ignoreHardDeletedMessagesPredicate = NSPredicate(
            format: "isHardDeleted == NO"
        )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            deletedMessagesPredicate,
            ignoreHardDeletedMessagesPredicate
        ])
    }

    /// Returns a predicate that filters out all deleted messages
    private static func nonDeletedMessagesPredicate() -> NSPredicate {
        .init(format: "deletedAt == nil")
    }

    private static func ignoreDraftMessagesPredicate() -> NSPredicate {
        .init(format: "isDraft == NO")
    }

    private static func channelPredicate(with cid: String) -> NSPredicate {
        .init(format: "channel.cid == %@", cid)
    }

    private static func messageSentPredicate() -> NSPredicate {
        .init(format: "localMessageStateRaw == nil")
    }

    /// Returns predicate for displaying messages after the channel truncation date.
    private static func nonTruncatedMessagesPredicate() -> NSCompoundPredicate {
        .init(orPredicateWithSubpredicates: [
            .init(format: "channel.truncatedAt == nil"),
            .init(format: "createdAt >= channel.truncatedAt")
        ])
    }

    /// Returns predicate for the channel preview message.
    private static func previewMessagePredicate(cid: String, includeShadowedMessages: Bool) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            channelMessagesPredicate(
                for: cid,
                deletedMessagesVisibility: .alwaysHidden,
                shouldShowShadowedMessages: includeShadowedMessages,
                filterNewerMessages: false
            ),
            .init(format: "type != %@", MessageType.ephemeral.rawValue),
            .init(format: "type != %@", MessageType.error.rawValue)
        ])
    }

    /// Returns predicate with channel messages and replies that should be shown in channel.
    static func channelMessagesPredicate(
        for cid: String,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool,
        filterNewerMessages: Bool = true
    ) -> NSCompoundPredicate {
        let channelMessagePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "showReplyInChannel == 1"),
            .init(format: "parentMessageId == nil")
        ])

        let validTypes = [
            MessageType.regular.rawValue,
            MessageType.ephemeral.rawValue,
            MessageType.system.rawValue,
            MessageType.deleted.rawValue,
            MessageType.error.rawValue
        ]

        let messageTypePredicate = NSCompoundPredicate(format: "type IN %@", validTypes)

        // Some pinned messages might be in the local database, but should not be fetched
        // if they do not belong to the regular channel query.
        let ignoreOlderMessagesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "channel.oldestMessageAt == nil"),
            .init(format: "createdAt >= channel.oldestMessageAt")
        ])

        var subpredicates = [
            channelPredicate(with: cid),
            channelMessagePredicate,
            messageTypePredicate,
            nonTruncatedMessagesPredicate(),
            ignoreOlderMessagesPredicate,
            deletedMessagesPredicate(deletedMessagesVisibility: deletedMessagesVisibility),
            ignoreDraftMessagesPredicate()
        ]

        if filterNewerMessages {
            // Used for paginating newer messages while jumping to a mid-page.
            // We want to avoid new messages being inserted in the UI if we are in a mid-page.
            let ignoreNewerMessagesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                .init(format: "channel.newestMessageAt == nil"),
                .init(format: "createdAt <= channel.newestMessageAt")
            ])
            subpredicates.append(ignoreNewerMessagesPredicate)
        }

        if !shouldShowShadowedMessages {
            let ignoreShadowedMessages = NSPredicate(format: "isShadowed == NO")
            subpredicates.append(ignoreShadowedMessages)
        }

        return .init(andPredicateWithSubpredicates: subpredicates)
    }

    /// Returns predicate with thread messages that should be shown in the thread.
    static func threadRepliesPredicate(
        for messageId: MessageId,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool
    ) -> NSCompoundPredicate {
        let replyMessage = NSPredicate(format: "parentMessageId == %@", messageId)
        let shouldShowInsideThread = NSPredicate(format: "showInsideThread == YES")

        let ignoreNewerRepliesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "parentMessage.newestReplyAt == nil"),
            .init(format: "createdAt <= parentMessage.newestReplyAt")
        ])

        var subpredicates = [
            ignoreDraftMessagesPredicate(),
            replyMessage,
            shouldShowInsideThread,
            ignoreNewerRepliesPredicate,
            deletedMessagesPredicate(deletedMessagesVisibility: deletedMessagesVisibility),
            nonTruncatedMessagesPredicate()
        ]

        if !shouldShowShadowedMessages {
            let ignoreShadowedMessages = NSPredicate(format: "isShadowed == NO")
            subpredicates.append(ignoreShadowedMessages)
        }

        return .init(andPredicateWithSubpredicates: subpredicates)
    }

    private static func sentMessagesPredicate(for cid: String) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            channelPredicate(with: cid),
            messageSentPredicate(),
            nonTruncatedMessagesPredicate(),
            nonDeletedMessagesPredicate(),
            ignoreDraftMessagesPredicate()
        ])
    }

    /// Returns a fetch request for messages from the channel with the provided `cid`.
    static func messagesFetchRequest(
        for cid: ChannelId,
        pageSize: Int,
        sortAscending: Bool = false,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool
    ) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = channelMessagesPredicate(
            for: cid.rawValue,
            deletedMessagesVisibility: deletedMessagesVisibility,
            shouldShowShadowedMessages: shouldShowShadowedMessages
        )
        request.fetchLimit = pageSize
        request.fetchBatchSize = pageSize
        return request
    }

    /// Returns a fetch request for replies for the specified `parentMessageId`.
    static func repliesFetchRequest(
        for messageId: MessageId,
        pageSize: Int,
        sortAscending: Bool = false,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool
    ) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = threadRepliesPredicate(
            for: messageId,
            deletedMessagesVisibility: deletedMessagesVisibility,
            shouldShowShadowedMessages: shouldShowShadowedMessages
        )
        request.fetchLimit = pageSize
        request.fetchBatchSize = pageSize
        return request
    }

    static func messagesFetchRequest(for query: MessageSearchQuery) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "ANY searches.filterHash == %@", query.filterHash),
            NSPredicate(format: "isHardDeleted == NO"),
            ignoreDraftMessagesPredicate()
        ])
        let sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        request.sortDescriptors = sortDescriptors.isEmpty ? [MessageSearchSortingKey.defaultSortDescriptor] : sortDescriptors
        return request
    }

    /// Returns a fetch request for the dto with a specific `messageId`.
    static func message(withID messageId: MessageId) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", messageId)
        return request
    }

    static func load(
        for cid: String,
        limit: Int,
        offset: Int = 0,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool,
        context: NSManagedObjectContext
    ) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.predicate = channelMessagesPredicate(
            for: cid,
            deletedMessagesVisibility: deletedMessagesVisibility,
            shouldShowShadowedMessages: shouldShowShadowedMessages
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return load(by: request, context: context)
    }

    static func preview(for cid: String, context: NSManagedObjectContext) -> MessageDTO? {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.predicate = previewMessagePredicate(
            cid: cid,
            includeShadowedMessages: context.chatClientConfig?.shouldShowShadowedMessages ?? false
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchOffset = 0
        request.fetchLimit = 1

        return load(by: request, context: context).first
    }

    static func load(id: String, context: NSManagedObjectContext) -> MessageDTO? {
        load(by: id, context: context).first
    }

    static func loadOrCreate(id: String, context: NSManagedObjectContext, cache: PreWarmedCache?) -> MessageDTO {
        if let cachedObject = cache?.model(for: id, context: context, type: MessageDTO.self) {
            return cachedObject
        }

        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        new.latestReactions = []
        new.ownReactions = []
        return new
    }

    /// Load replies for the specified `parentMessageId`.
    static func loadReplies(
        for messageId: MessageId,
        limit: Int,
        offset: Int = 0,
        context: NSManagedObjectContext
    ) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.predicate = NSPredicate(format: "parentMessageId == %@", messageId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return load(by: request, context: context)
    }

    static func loadCurrentUserMessages(
        in cid: String,
        createdAtFrom: Date,
        createdAtThrough: Date,
        context: NSManagedObjectContext
    ) -> [MessageDTO] {
        let subpredicates: [NSPredicate] = [
            sentMessagesPredicate(for: cid),
            .init(format: "user.currentUser != nil"),
            .init(format: "createdAt > %@", createdAtFrom.bridgeDate),
            .init(format: "createdAt <= %@", createdAtThrough.bridgeDate)
        ]

        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: false)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)

        return (try? context.fetch(request)) ?? []
    }

    static func countOtherUserMessages(
        in cid: String,
        createdAtFrom: Date,
        context: NSManagedObjectContext
    ) -> Int {
        let subpredicates: [NSPredicate] = [
            sentMessagesPredicate(for: cid),
            .init(format: "createdAt >= %@", createdAtFrom.bridgeDate),
            .init(format: "user.currentUser == nil")
        ]

        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: false)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)

        return (try? context.count(for: request)) ?? 0
    }

    static func numberOfReads(for messageId: MessageId, context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<ChannelReadDTO>(entityName: ChannelReadDTO.entityName)
        request.predicate = NSPredicate(format: "readMessagesFromCurrentUser.id CONTAINS %@", messageId)
        return (try? context.count(for: request)) ?? 0
    }

    static func loadSendingMessages(context: NSManagedObjectContext) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.locallyCreatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "localMessageStateRaw == %@", LocalMessageState.sending.rawValue)
        return load(by: request, context: context)
    }
    
    static func loadMessage(
        before id: MessageId,
        cid: String,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool,
        context: NSManagedObjectContext
    ) throws -> MessageDTO? {
        guard let message = load(id: id, context: context) else { return nil }
        
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            channelMessagesPredicate(for: cid, deletedMessagesVisibility: deletedMessagesVisibility, shouldShowShadowedMessages: shouldShowShadowedMessages),
            .init(format: "id != %@", id),
            .init(format: "createdAt <= %@", message.createdAt)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    static func loadMessages(
        from fromIncludingDate: Date,
        to toIncludingDate: Date,
        in cid: ChannelId,
        sortAscending: Bool,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool,
        context: NSManagedObjectContext
    ) throws -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            channelMessagesPredicate(
                for: cid.rawValue,
                deletedMessagesVisibility: deletedMessagesVisibility,
                shouldShowShadowedMessages: shouldShowShadowedMessages
            ),
            .init(format: "createdAt >= %@", fromIncludingDate.bridgeDate),
            .init(format: "createdAt <= %@", toIncludingDate.bridgeDate)
        ])
        return try load(request, context: context)
    }

    /// Fetches all active location messages in a channel or all channels of the current user.
    /// If `channelId` is nil, it will fetch all messages independent of the channel.
    static func currentUserActiveLiveLocationMessagesFetchRequest(
        currentUserId: UserId,
        channelId: ChannelId?
    ) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        // Hard coded limit for now. 10 live locations messages at the same should be more than enough.
        request.fetchLimit = 10
        request.sortDescriptors = [NSSortDescriptor(
            keyPath: \MessageDTO.createdAt,
            ascending: true
        )]
        var predicates: [NSPredicate] = [
            .init(format: "isActiveLiveLocation == YES"),
            .init(format: "user.id == %@", currentUserId),
            .init(format: "localMessageStateRaw == nil")
        ]
        if let channelId {
            predicates.append(.init(format: "channel.cid == %@", channelId.rawValue))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return request
    }

    /// Fetches all active location messages in any given channel and from every user.
    static func activeLiveLocationMessagesFetchRequest() -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.fetchLimit = 25
        request.sortDescriptors = [NSSortDescriptor(
            keyPath: \MessageDTO.createdAt,
            ascending: true
        )]
        let predicates: [NSPredicate] = [
            .init(format: "isActiveLiveLocation == YES"),
            .init(format: "localMessageStateRaw == nil")
        ]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return request
    }

    static func loadCurrentUserActiveLiveLocationMessages(
        currentUserId: UserId,
        channelId: ChannelId?,
        context: NSManagedObjectContext
    ) throws -> [MessageDTO] {
        let request = currentUserActiveLiveLocationMessagesFetchRequest(currentUserId: currentUserId, channelId: channelId)
        return try load(request, context: context)
    }

    static func loadReplies(
        from fromIncludingDate: Date,
        to toIncludingDate: Date,
        in messageId: MessageId,
        sortAscending: Bool,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool,
        context: NSManagedObjectContext
    ) throws -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        MessageDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            threadRepliesPredicate(
                for: messageId,
                deletedMessagesVisibility: deletedMessagesVisibility,
                shouldShowShadowedMessages: shouldShowShadowedMessages
            ),
            .init(format: "createdAt >= %@", fromIncludingDate.bridgeDate),
            .init(format: "createdAt <= %@", toIncludingDate.bridgeDate)
        ])
        return try load(request, context: context)
    }
}

// MARK: - State Helpers

extension MessageDTO {
    /// A possible additional local state of the message. Applies only for the messages of the current user.
    var localMessageState: LocalMessageState? {
        get { localMessageStateRaw.flatMap(LocalMessageState.init(rawValue:)) }
        set { localMessageStateRaw = newValue?.rawValue }
    }

    var isLocalOnly: Bool {
        if let localMessageState = self.localMessageState {
            return localMessageState.isLocalOnly
        }

        return type == MessageType.ephemeral.rawValue || type == MessageType.error.rawValue
    }
}

extension NSManagedObjectContext: MessageDatabaseSession {
    func createNewMessage(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        isSystem: Bool,
        quotedMessageId: MessageId?,
        createdAt: Date?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        poll: PollPayload?,
        location: NewLocationInfo?,
        restrictedVisibility: [UserId],
        extraData: [String: RawJSON]
    ) throws -> MessageDTO {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        guard let channelDTO = ChannelDTO.load(cid: cid, context: self) else {
            throw ClientError.ChannelDoesNotExist(cid: cid)
        }

        let id = messageId ?? .newUniqueId
        let message = MessageDTO.loadOrCreate(id: id, context: self, cache: nil)

        // We make `createdDate` 0.1 second bigger than Channel's most recent message
        // so if the local time is not in sync, the message will still appear in the correct position
        // even if the sending fails
        let createdAt = createdAt ?? (max(channelDTO.lastMessageAt?.addingTimeInterval(0.1).bridgeDate ?? Date(), Date()))
        message.locallyCreatedAt = createdAt.bridgeDate
        // It's fine that we're saving an incorrect value for `createdAt` and `updatedAt`
        // When message is successfully sent, backend sends the actual dates
        // and these are set correctly in `saveMessage`
        message.createdAt = createdAt.bridgeDate
        message.updatedAt = createdAt.bridgeDate

        if let pinning = pinning {
            try pin(message: message, pinning: pinning)
        }

        message.cid = cid.rawValue
        message.text = text
        message.command = command
        message.args = arguments
        message.parentMessageId = parentMessageId
        message.extraData = try JSONEncoder.default.encode(extraData)
        message.isSilent = isSilent
        message.skipPush = skipPush
        message.skipEnrichUrl = skipEnrichUrl
        message.reactionScores = [:]
        message.reactionCounts = [:]
        message.reactionGroups = []
        message.restrictedVisibility = Set(restrictedVisibility)

        // Message type
        if parentMessageId != nil {
            message.type = MessageType.reply.rawValue
        } else if isSystem {
            message.type = MessageType.system.rawValue
        } else {
            message.type = MessageType.regular.rawValue
        }

        if let poll {
            message.poll = try? savePoll(payload: poll, cache: nil)
        }

        if let location {
            guard let deviceId = currentUserDTO.currentDevice?.id else {
                throw ClientError.CurrentUserDoesNotHaveDeviceRegistered()
            }
            message.location = try? saveLocation(
                payload: .init(
                    channelId: cid.rawValue,
                    messageId: id,
                    userId: currentUserDTO.user.id,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    createdAt: Date(),
                    updatedAt: Date(),
                    endAt: location.endAt,
                    createdByDeviceId: deviceId
                ),
                cache: nil
            )
        }

        message.attachments = Set(
            try attachments.enumerated().map { index, attachment in
                let id = AttachmentId(cid: cid, messageId: message.id, index: index)
                return try createNewAttachment(attachment: attachment, id: id)
            }
        )

        message.mentionedUserIds = mentionedUserIds

        message.showReplyInChannel = showReplyInChannel
        message.quotedMessage = quotedMessageId.flatMap { MessageDTO.load(id: $0, context: self) }

        message.user = currentUserDTO.user
        message.channel = channelDTO

        let shouldNotUpdateLastMessageAt = isSystem && channelDTO.config.skipLastMsgAtUpdateForSystemMsg
        if !shouldNotUpdateLastMessageAt {
            let newLastMessageAt = max(channelDTO.lastMessageAt?.bridgeDate ?? createdAt, createdAt).bridgeDate
            channelDTO.lastMessageAt = newLastMessageAt
            channelDTO.defaultSortingAt = newLastMessageAt
        }

        if let parentMessageId = parentMessageId,
           let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self) {
            parentMessageDTO.replies.insert(message)
            parentMessageDTO.replyCount += 1
        }

        // When the current user submits the new message that will be shown
        // in the channel for sending - make it a channel preview.
        if parentMessageId == nil || showReplyInChannel {
            channelDTO.previewMessage = message
        }

        return message
    }

    func createNewDraftMessage(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        extraData: [String: RawJSON]
    ) throws -> MessageDTO {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        guard let channelDTO = ChannelDTO.load(cid: cid, context: self) else {
            throw ClientError.ChannelDoesNotExist(cid: cid)
        }

        /// Makes sure to delete the existing draft message if it exists.
        deleteDraftMessage(in: cid, threadId: parentMessageId)

        let createdAt = Date()
        let message = MessageDTO.loadOrCreate(id: .newUniqueId, context: self, cache: nil)
        message.isDraft = true
        message.locallyCreatedAt = createdAt.bridgeDate
        message.createdAt = createdAt.bridgeDate
        message.updatedAt = createdAt.bridgeDate
        message.cid = cid.rawValue
        message.text = text
        message.command = command
        message.args = arguments
        message.parentMessageId = parentMessageId
        message.extraData = try JSONEncoder.default.encode(extraData)
        message.isSilent = isSilent
        message.skipPush = false
        message.skipEnrichUrl = false
        message.reactionScores = [:]
        message.reactionCounts = [:]
        message.reactionGroups = []
        message.mentionedUserIds = mentionedUserIds
        message.showReplyInChannel = showReplyInChannel
        message.quotedMessage = quotedMessageId.flatMap { MessageDTO.load(id: $0, context: self) }
        message.user = currentUserDTO.user
        message.channel = channelDTO
        message.attachments = Set(
            try attachments.enumerated().map { index, attachment in
                let id = AttachmentId(cid: cid, messageId: message.id, index: index)
                return try createNewAttachment(attachment: attachment, id: id)
            }
        )

        if parentMessageId != nil {
            message.type = MessageType.reply.rawValue
        } else {
            message.type = MessageType.regular.rawValue
        }

        if let threadId = parentMessageId {
            let parentMessageDTO = self.message(id: threadId)
            message.draftOfThread = parentMessageDTO
            let threadDTO = thread(parentMessageId: threadId, cache: nil)
            threadDTO?.parentMessageId = threadId
        } else {
            message.channel?.draftMessage = message
        }

        return message
    }
    
    // swiftlint:disable function_body_length

    /// Saves a message into the local DB.
    /// - Parameters:
    ///   - payload: The message payload
    ///   - channelDTO: The channel dto.
    ///   - syncOwnReactions: Whether to sync own reactions. It should be set to `true` when the payload comes from an API response and `false` when the payload is received via WS events. For performance reasons the API
    ///   does not populate the `message.own_reactions` when sending events
    ///   - skipDraftUpdate: Whether to skip draft update. This is used when saving quoted and parent messages from
    ///   saveDraftMessage function to avoid an infinite loop since saving the draft would be called again.
    ///   - cache: The pre-warmed cache.
    func saveMessage(
        payload: MessagePayload,
        channelDTO: ChannelDTO,
        syncOwnReactions: Bool,
        skipDraftUpdate: Bool = false,
        cache: PreWarmedCache?
    ) throws -> MessageDTO {
        let cid = try ChannelId(cid: channelDTO.cid)
        let dto = MessageDTO.loadOrCreate(id: payload.id, context: self, cache: cache)

        if dto.localMessageState == .pendingSend || dto.localMessageState == .pendingSync {
            return dto
        }

        // Local text edit before receiving the WS event
        if let localDate = dto.textUpdatedAt?.bridgeDate,
           let payloadDate = payload.messageTextUpdatedAt,
           localDate > payloadDate {
            return dto
        }

        dto.cid = payload.cid?.rawValue
        dto.text = payload.text
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.deletedAt = payload.deletedAt?.bridgeDate
        dto.textUpdatedAt = payload.messageTextUpdatedAt?.bridgeDate
        dto.type = payload.type.rawValue
        dto.command = payload.command
        dto.args = payload.args
        dto.parentMessageId = payload.parentId
        dto.showReplyInChannel = payload.showReplyInChannel
        dto.replyCount = Int32(payload.replyCount)

        do {
            dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        } catch {
            log.error(
                "Failed to decode extra payload for Message with id: <\(dto.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }

        dto.isSilent = payload.isSilent
        dto.isShadowed = payload.isShadowed
        // Due to backend not working as advertised
        // (sending `shadowed: true` flag to the shadow banned user)
        // we have to implement this workaround to get the advertised behavior
        // info on slack: https://getstream.slack.com/archives/CE5N802GP/p1635785568060500
        // TODO: Remove the workaround once backend bug is fixed
        if currentUser?.user.id == payload.user.id {
            dto.isShadowed = false
        }

        dto.pinned = payload.pinned
        dto.pinExpires = payload.pinExpires?.bridgeDate
        dto.pinnedAt = payload.pinnedAt?.bridgeDate
        if let pinnedByUser = payload.pinnedBy {
            dto.pinnedBy = try saveUser(payload: pinnedByUser)
        }

        if dto.pinned && !channelDTO.pinnedMessages.contains(dto) {
            channelDTO.pinnedMessages.insert(dto)
        } else if !dto.pinned {
            channelDTO.pinnedMessages.remove(dto)
        }

        if let quotedMessageId = payload.quotedMessageId,
           let quotedMessage = message(id: quotedMessageId) {
            // In case we do not have a fully formed quoted message in the payload,
            // we check for quotedMessageId. This can happen in the case of nested quoted messages.
            dto.quotedMessage = quotedMessage
        } else if let quotedMessage = payload.quotedMessage {
            dto.quotedMessage = try saveMessage(
                payload: quotedMessage,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                skipDraftUpdate: false,
                cache: cache
            )
        } else {
            dto.quotedMessage = nil
        }

        if let draft = payload.draft, skipDraftUpdate == false {
            dto.draftReply = try saveDraftMessage(payload: draft, for: cid, cache: cache)
        } else if skipDraftUpdate == false {
            /// If the payload does not contain a draft reply, we should
            /// delete the existing draft reply if it exists.
            if let draft = dto.draftReply {
                deleteDraftMessage(in: cid, threadId: draft.parentMessageId)
                dto.draftReply = nil
            }
        }

        if let location = payload.location {
            dto.location = try saveLocation(payload: location, cache: cache)
        }

        let user = try saveUser(payload: payload.user)
        dto.user = user

        dto.reactionScores = payload.reactionScores.mapKeys { $0.rawValue }
        dto.reactionCounts = payload.reactionCounts.mapKeys { $0.rawValue }
        dto.reactionGroups = Set(payload.reactionGroups.map { (type, groupPayload) in
            MessageReactionGroupDTO(
                type: type,
                payload: groupPayload,
                context: self
            )
        })

        // If user edited their message to remove mentioned users, we need to get rid of it
        // as backend does
        dto.mentionedUsers = try Set(payload.mentionedUsers.map {
            let user = try saveUser(payload: $0)
            return user
        })
        dto.mentionedUserIds = payload.mentionedUsers.map(\.id)

        // If user participated in thread, but deleted message later, we need to get rid of it if backends does
        dto.threadParticipants = try NSOrderedSet(
            array: payload.threadParticipants.map { try saveUser(payload: $0) }
        )
        let restrictedVisibility = Set(payload.restrictedVisibility)
        dto.restrictedVisibility = restrictedVisibility.isEmpty ? nil : restrictedVisibility

        let isSystemMessage = dto.type == MessageType.system.rawValue
        let shouldNotUpdateLastMessageAt = isSystemMessage && channelDTO.config.skipLastMsgAtUpdateForSystemMsg
        if !shouldNotUpdateLastMessageAt {
            channelDTO.lastMessageAt = max(channelDTO.lastMessageAt?.bridgeDate ?? payload.createdAt, payload.createdAt).bridgeDate
        }
        
        dto.channel = channelDTO

        dto.latestReactions = payload
            .latestReactions
            .compactMap { try? saveReaction(payload: $0, query: nil, cache: cache) }
            .map(\.id)

        if syncOwnReactions {
            dto.ownReactions = payload
                .ownReactions
                .compactMap { try? saveReaction(payload: $0, query: nil, cache: cache) }
                .map(\.id)
        }

        let attachments: Set<AttachmentDTO> = try Set(
            payload.attachments.enumerated().map { index, attachment in
                let id = AttachmentId(cid: cid, messageId: payload.id, index: index)
                let dto = try saveAttachment(payload: attachment, id: id)
                return dto
            }
        )
        dto.attachments = attachments

        if let poll = payload.poll {
            let pollDto = try savePoll(payload: poll, cache: cache)
            dto.poll = pollDto
        }

        // Only insert message into Parent's replies if not already present.
        // This in theory would not be needed since replies is a Set, but
        // it will trigger an FRC update, which will cause the message to disappear
        // in the Message List if there is already a message with the same ID.
        if let parentMessageId = payload.parentId,
           let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self),
           !parentMessageDTO.replies.contains(dto) {
            parentMessageDTO.replies.insert(dto)
        }

        dto.translations = payload.translations?.mapKeys { $0.languageCode }
        dto.originalLanguage = payload.originalLanguage

        if let moderationPayload = payload.moderation {
            dto.moderationDetails = MessageModerationDetailsDTO.create(
                from: moderationPayload,
                isV1: false,
                context: self
            )
        } else if let moderationDetailsPayload = payload.moderationDetails {
            dto.moderationDetails = MessageModerationDetailsDTO.create(
                from: moderationDetailsPayload,
                isV1: true,
                context: self
            )
        } else {
            dto.moderationDetails = nil
        }

        // Calculate reads if the message is authored by the current user.
        if payload.user.id == currentUser?.user.id {
            dto.updateReadBy(withChannelReads: channelDTO.reads)
        }

        if let reminder = payload.reminder {
            dto.reminder = try saveReminder(payload: reminder, cache: cache)
        } else if let reminderDTO = dto.reminder {
            delete(reminderDTO)
            dto.reminder = nil
        }

        // Refetch channel preview if the current preview has changed.
        //
        // The current message can stop being a valid preview e.g.
        // if it didn't pass moderation and obtained `error` type.
        if payload.id == channelDTO.previewMessage?.id {
            channelDTO.previewMessage = preview(for: cid)
        }

        return dto
    }

    // swiftlint:enable function_body_length

    func saveMessages(
        messagesPayload: MessageListPayload,
        for cid: ChannelId?,
        syncOwnReactions: Bool = true
    ) -> [MessageDTO] {
        let cache = messagesPayload.getPayloadToModelIdMappings(context: self)
        return messagesPayload.messages.compactMapLoggingError {
            try saveMessage(
                payload: $0,
                for: cid,
                syncOwnReactions: syncOwnReactions,
                skipDraftUpdate: false,
                cache: cache
            )
        }
    }

    func saveMessage(
        payload: MessagePayload,
        for cid: ChannelId?,
        syncOwnReactions: Bool = true,
        skipDraftUpdate: Bool = false,
        cache: PreWarmedCache?
    ) throws -> MessageDTO {
        guard payload.channel != nil || cid != nil else {
            throw ClientError.MessagePayloadSavingFailure("""
            Either `payload.channel` or `cid` must be provided to sucessfuly save the message payload.
            - `payload.channel` value: \(String(describing: payload.channel))
            - `cid` value: \(String(describing: cid))
            """)
        }

        if let cid = cid, let payloadCid = payload.channel?.cid {
            log.assert(cid == payloadCid, "`cid` provided is different from the `payload.channel.cid`.")
        }

        var channelDTO: ChannelDTO?

        if let channelPayload = payload.channel {
            channelDTO = try saveChannel(payload: channelPayload, query: nil, cache: cache)
        } else if let cid = cid {
            channelDTO = ChannelDTO.load(cid: cid, context: self)
        } else {
            let description = "Should never happen because either `cid` or `payload.channel` should be present."
            log.assertionFailure(description)
            throw ClientError.MessagePayloadSavingFailure(description)
        }

        guard let channel = channelDTO else {
            let description = "Should never happen, a channel should have been fetched."
            log.assertionFailure(description)
            throw ClientError.MessagePayloadSavingFailure(description)
        }

        return try saveMessage(
            payload: payload,
            channelDTO: channel,
            syncOwnReactions: syncOwnReactions,
            skipDraftUpdate: skipDraftUpdate,
            cache: cache
        )
    }

    @discardableResult
    func saveDraftMessage(
        payload: DraftPayload,
        for cid: ChannelId,
        cache: PreWarmedCache?
    ) throws -> MessageDTO {
        let draftDetailsPayload = payload.message
        let channelDTO: ChannelDTO?
        if let channelPayload = payload.channelPayload {
            channelDTO = try saveChannel(payload: channelPayload, query: nil, cache: cache)
        } else {
            channelDTO = ChannelDTO.load(cid: cid, context: self)
        }
        guard let channelDTO = channelDTO else {
            throw ClientError.ChannelDoesNotExist(cid: cid)
        }
        guard let user = currentUser?.user else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        let dto = MessageDTO.loadOrCreate(id: draftDetailsPayload.id, context: self, cache: cache)
        dto.cid = cid.rawValue
        dto.text = draftDetailsPayload.text
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.createdAt.bridgeDate
        dto.reactionScores = [:]
        dto.reactionCounts = [:]
        dto.type = MessageType.regular.rawValue
        dto.command = draftDetailsPayload.command
        dto.args = draftDetailsPayload.args
        dto.parentMessageId = payload.parentId
        dto.showReplyInChannel = draftDetailsPayload.showReplyInChannel
        dto.isSilent = draftDetailsPayload.isSilent
        dto.user = user
        dto.channel = channelDTO
        dto.isDraft = true

        if let threadId = payload.parentId {
            let threadDTO = thread(parentMessageId: threadId, cache: cache)
            threadDTO?.parentMessageId = threadId
        }

        if let parentMessage = payload.parentMessage {
            dto.parentMessage = try saveMessage(
                payload: parentMessage,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: cache
            )
            dto.draftOfThread = dto.parentMessage
        } else if let parentMessageId = payload.parentId,
                  let parentMessage = message(id: parentMessageId) {
            dto.parentMessage = parentMessage
            dto.draftOfThread = parentMessage
        } else {
            dto.parentMessage = nil
            dto.draftOfThread = nil
            channelDTO.draftMessage = dto
        }

        if let quotedMessage = payload.quotedMessage {
            dto.quotedMessage = try saveMessage(
                payload: quotedMessage,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: cache
            )
        } else {
            dto.quotedMessage = nil
        }

        if let mentionedUsers = draftDetailsPayload.mentionedUsers {
            dto.mentionedUsers = try Set(mentionedUsers.map { try saveUser(payload: $0) })
            dto.mentionedUserIds = mentionedUsers.map(\.id)
        }

        if let attachments = draftDetailsPayload.attachments {
            dto.attachments = Set(
                try attachments.enumerated().map { index, attachment in
                    let id = AttachmentId(cid: cid, messageId: draftDetailsPayload.id, index: index)
                    return try saveAttachment(payload: attachment, id: id)
                }
            )
        }

        do {
            dto.extraData = try JSONEncoder.default.encode(draftDetailsPayload.extraData)
        } catch {
            log.error(
                "Failed to decode extra payload for Message with id: <\(dto.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }

        return dto
    }

    func saveMessage(payload: MessagePayload, for query: MessageSearchQuery, cache: PreWarmedCache?) throws -> MessageDTO {
        let messageDTO = try saveMessage(payload: payload, for: nil, cache: cache)
        messageDTO.searches.insert(saveQuery(query: query))
        return messageDTO
    }

    func deleteDraftMessage(in cid: ChannelId, threadId: MessageId?) {
        if let threadId = threadId, let parentMessage = message(id: threadId) {
            parentMessage.draftReply.map {
                delete($0)
            }
            // Trigger thread update
            let thread = thread(parentMessageId: threadId, cache: nil)
            thread?.parentMessageId = threadId
        } else if let channel = channel(cid: cid) {
            channel.draftMessage.map {
                delete($0)
            }
        }
    }

    func message(id: MessageId) -> MessageDTO? { .load(id: id, context: self) }

    func messageExists(id: MessageId) -> Bool {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        do {
            let count = try count(for: request)
            return count != 0
        } catch {
            return false
        }
    }

    func delete(message: MessageDTO) {
        delete(message)
    }

    func pin(message: MessageDTO, pinning: MessagePinning) throws {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        let pinnedDate = DBDate()
        message.pinned = true
        message.pinnedAt = pinnedDate
        message.pinnedBy = currentUserDTO.user
        message.pinExpires = pinning.expirationDate?.bridgeDate
    }

    func unpin(message: MessageDTO) {
        message.pinned = false
        message.pinnedAt = nil
        message.pinnedBy = nil
        message.pinExpires = nil
    }

    /// Adds the reaction for the current user to the message with id `messageId`
    ///
    /// Notes:
    /// - The reaction is added to the database and it updates the message `reactionScores` property
    /// - This method will throw if there is no current user set
    /// - If the message is not found, there will be no side effect and the method will return `nil`
    /// - If a reaction for the same user, type and message exists
    func addReaction(
        to messageId: MessageId,
        type: MessageReactionType,
        score: Int,
        enforceUnique: Bool,
        extraData: [String: RawJSON],
        localState: LocalReactionState?
    ) throws -> MessageReactionDTO {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        guard let message = MessageDTO.load(id: messageId, context: self) else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }

        let dto = MessageReactionDTO.loadOrCreate(
            message: message,
            type: type,
            user: currentUserDTO.user,
            context: self,
            cache: nil
        )

        // If enforceUnique is true erase all the other reactions from the current user and decrement the scores/counts.
        if enforceUnique {
            let previousOwnReactionTypes = message.ownReactions.map(\.reactionType)
            previousOwnReactionTypes.forEach { type in
                message.reactionScores[type]? -= score
                message.reactionCounts[type]? -= 1
                let reactionGroup = message.reactionGroups.first(where: { $0.type == type })
                reactionGroup?.sumScores -= Int64(score)
                reactionGroup?.count -= 1
            }

            message.ownReactions = []
            message.latestReactions.removeAll { $0.reactionUserId == currentUserDTO.user.id }
        }

        // Update reaction scores
        if let reactionScore = message.reactionScores[type.rawValue] {
            message.reactionScores[type.rawValue]? += reactionScore
        } else {
            message.reactionScores[type.rawValue] = score
        }

        // Update reaction counts
        if let reactionCount = message.reactionCounts[type.rawValue] {
            message.reactionCounts[type.rawValue] = reactionCount + 1
        } else {
            message.reactionCounts[type.rawValue] = 1
        }

        // Update grouped reactions
        if let existingReactionGroup = message.reactionGroups.first(where: { $0.type == type.rawValue }),
           let reactionCount = message.reactionCounts[type.rawValue],
           let reactionScore = message.reactionScores[type.rawValue] {
            existingReactionGroup.count = Int64(reactionCount)
            existingReactionGroup.sumScores = Int64(reactionScore)
            existingReactionGroup.lastReactionAt = DBDate()
        } else {
            let newReactionGroup = MessageReactionGroupDTO(
                type: type,
                sumScores: score,
                count: 1,
                firstReactionAt: Date(),
                lastReactionAt: Date(),
                context: self
            )
            message.reactionGroups.insert(newReactionGroup)
        }

        dto.score = Int64(score)
        dto.extraData = try JSONEncoder.default.encode(extraData)
        dto.localState = localState

        let reactionId = dto.id

        if !message.latestReactions.contains(reactionId) {
            message.latestReactions.append(reactionId)
        }

        if !message.ownReactions.contains(reactionId) {
            message.ownReactions.append(reactionId)
        }

        return dto
    }

    /// Removes the reaction for the current user to the message with id `messageId`
    ///
    /// Notes:
    /// - The reaction is *not* removed from the database
    /// - This method will throw if there is no current user set
    /// - If the message is not found, there will be no side effect and the method will return `nil`
    /// - If there is no reaction found in the database, this method returns `nil`
    func removeReaction(from messageId: MessageId, type: MessageReactionType, on version: String?) throws -> MessageReactionDTO? {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        guard let message = MessageDTO.load(id: messageId, context: self) else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }

        guard let reaction = MessageReactionDTO
            .load(userId: currentUserDTO.user.id, messageId: messageId, type: type, context: self) else {
            return nil
        }

        // if the reaction on the database does not match the version, do nothing
        guard version == nil || version == reaction.version else {
            return nil
        }

        message.latestReactions = message.latestReactions.filter { $0 != reaction.id }
        message.ownReactions = message.ownReactions.filter { $0 != reaction.id }

        guard let reactionScore = message.reactionScores[type.rawValue] else {
            return reaction
        }

        let newScore = max(reactionScore - Int(reaction.score), 0)
        message.reactionScores[type.rawValue] = newScore
        message.reactionCounts[type.rawValue]? -= 1

        let reactionGroup = message.reactionGroups.first(where: { $0.type == type.rawValue })
        reactionGroup?.sumScores = Int64(newScore)
        reactionGroup?.count -= 1
        
        let scoreIsZero = newScore == 0
        let countIsZero = message.reactionCounts[type.rawValue] == 0

        if scoreIsZero {
            message.reactionScores[type.rawValue] = nil
        }

        if countIsZero {
            message.reactionCounts[type.rawValue] = nil
        }

        if scoreIsZero && countIsZero, let reactionGroup = reactionGroup {
            message.reactionGroups.remove(reactionGroup)
        }

        return reaction
    }

    func preview(for cid: ChannelId) -> MessageDTO? {
        MessageDTO.preview(for: cid.rawValue, context: self)
    }

    func saveMessageSearch(payload: MessageSearchResultsPayload, for query: MessageSearchQuery) -> [MessageDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.results.compactMapLoggingError {
            try saveMessage(payload: $0.message, for: query, cache: cache)
        }
    }

    /// Changes the state to `.pendingSend` for all messages in `.sending` state. This method is expected to be used at the beginning of the session
    /// to avoid those from being stuck there in limbo.
    /// Messages can get stuck in `.sending` state if the network request to send them takes to much, and the app is backgrounded or killed.
    func rescueMessagesStuckInSending() {
        // Restart messages in sending state.
        let messages = MessageDTO.loadSendingMessages(context: self)
        messages.forEach {
            $0.localMessageState = .pendingSend
        }

        // Restart attachments that were in progress before the app was killed.
        let attachments = AttachmentDTO.loadInProgressAttachments(context: self)
        attachments.forEach {
            $0.localState = .pendingUpload
        }
    }
    
    func loadMessage(
        before id: MessageId,
        cid: String
    ) throws -> MessageDTO? {
        guard let clientConfig = chatClientConfig else { return nil }
        return try MessageDTO.loadMessage(
            before: id,
            cid: cid,
            deletedMessagesVisibility: clientConfig.deletedMessagesVisibility,
            shouldShowShadowedMessages: clientConfig.shouldShowShadowedMessages,
            context: self
        )
    }
    
    func loadMessages(
        from fromIncludingDate: Date,
        to toIncludingDate: Date,
        in cid: ChannelId,
        sortAscending: Bool
    ) throws -> [MessageDTO] {
        guard let clientConfig = chatClientConfig else { return [] }
        return try MessageDTO.loadMessages(
            from: fromIncludingDate,
            to: toIncludingDate,
            in: cid,
            sortAscending: sortAscending,
            deletedMessagesVisibility: clientConfig.deletedMessagesVisibility,
            shouldShowShadowedMessages: clientConfig.shouldShowShadowedMessages,
            context: self
        )
    }
    
    func loadReplies(
        from fromIncludingDate: Date,
        to toIncludingDate: Date,
        in messageId: MessageId,
        sortAscending: Bool
    ) throws -> [MessageDTO] {
        guard let clientConfig = chatClientConfig else { return [] }
        return try MessageDTO.loadReplies(
            from: fromIncludingDate,
            to: toIncludingDate,
            in: messageId,
            sortAscending: sortAscending,
            deletedMessagesVisibility: clientConfig.deletedMessagesVisibility,
            shouldShowShadowedMessages: clientConfig.shouldShowShadowedMessages,
            context: self
        )
    }
}

extension MessageDTO {
    override class func prefetchedRelationshipKeyPaths() -> [String] {
        [
            KeyPath.string(\MessageDTO.attachments),
            KeyPath.string(\MessageDTO.flaggedBy),
            KeyPath.string(\MessageDTO.mentionedUsers),
            KeyPath.string(\MessageDTO.moderationDetails),
            KeyPath.string(\MessageDTO.pinnedBy),
            KeyPath.string(\MessageDTO.poll),
            KeyPath.string(\MessageDTO.quotedBy),
            KeyPath.string(\MessageDTO.quotedMessage),
            KeyPath.string(\MessageDTO.reactionGroups),
            KeyPath.string(\MessageDTO.reads),
            KeyPath.string(\MessageDTO.replies),
            KeyPath.string(\MessageDTO.threadParticipants),
            KeyPath.string(\MessageDTO.user)
        ]
    }
}

extension MessageDTO {
    /// Snapshots the current state of `MessageDTO` and returns an immutable model object from it.
    func asModel() throws -> ChatMessage { try .init(fromDTO: self, depth: 0) }

    /// Snapshots the current state of `MessageDTO` and returns an immutable model object from it if the dependency depth
    /// limit has not been reached
    func relationshipAsModel(depth: Int) throws -> ChatMessage? {
        do {
            return try ChatMessage(fromDTO: self, depth: depth + 1)
        } catch {
            if error is RecursionLimitError { return nil }
            throw error
        }
    }

    /// Snapshots the current state of `MessageDTO` and returns its representation for the use in API calls.
    func asRequestBody() -> MessageRequestBody {
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: self.extraData)
        } catch {
            log.assertionFailure("Failed decoding saved extra data with error: \(error). This should never happen because the extra data must be a valid JSON to be saved.")
            extraData = [:]
        }

        let uploadedAttachments: [MessageAttachmentPayload] = attachments
            .filter { $0.localState == .uploaded || $0.localState == nil }
            .sorted { ($0.attachmentID?.index ?? 0) < ($1.attachmentID?.index ?? 0) }
            .compactMap { $0.asRequestPayload() }

        // At the moment, we only provide the type for system messages when creating a message.
        let systemType = type == MessageType.system.rawValue ? type : nil
        
        var restrictedVisibilityArray: [UserId]?
        if let restrictedVisibility {
            restrictedVisibilityArray = Array(restrictedVisibility)
        }

        return .init(
            id: id,
            user: user.asRequestBody(),
            text: text,
            type: systemType,
            command: command,
            args: args,
            parentId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            isSilent: isSilent,
            quotedMessageId: quotedMessage?.id,
            attachments: uploadedAttachments,
            mentionedUserIds: mentionedUserIds,
            pinned: pinned,
            pinExpires: pinExpires?.bridgeDate,
            pollId: poll?.id,
            restrictedVisibility: restrictedVisibilityArray,
            location: location.map {
                .init(
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    endAt: $0.endAt?.bridgeDate,
                    createdByDeviceId: $0.deviceId
                )
            },
            extraData: extraData
        )
    }

    func asDraftRequestBody() -> DraftMessageRequestBody {
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: self.extraData)
        } catch {
            log.assertionFailure("Failed decoding saved extra data with error: \(error). This should never happen because the extra data must be a valid JSON to be saved.")
            extraData = [:]
        }

        let uploadedAttachments: [MessageAttachmentPayload] = attachments
            .filter { $0.localState == .uploaded || $0.localState == nil }
            .sorted { ($0.attachmentID?.index ?? 0) < ($1.attachmentID?.index ?? 0) }
            .compactMap { $0.asRequestPayload() }

        return .init(
            id: id,
            text: text,
            command: command,
            args: args,
            parentId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            isSilent: isSilent,
            quotedMessageId: quotedMessage?.id,
            attachments: uploadedAttachments,
            mentionedUserIds: mentionedUserIds,
            extraData: extraData
        )
    }

    /// The message has been successfully sent to the server.
    func markMessageAsSent() {
        locallyCreatedAt = nil
        localMessageState = nil
    }

    /// The message failed to be sent to the server.
    func markMessageAsFailed() {
        localMessageState = .sendingFailed
    }
    
    func updateReadBy(withChannelReads reads: Set<ChannelReadDTO>) {
        let createdAtInterval = createdAt.timeIntervalSince1970
        let messageUserId = user.id
        self.reads = reads.filter { read in
            read.user.id != messageUserId && read.lastReadAt.timeIntervalSince1970 >= createdAtInterval
        }
    }
}

private extension ChatMessage {
    // swiftlint:disable function_body_length
    init(fromDTO dto: MessageDTO, depth: Int) throws {
        guard StreamRuntimeCheck._canFetchRelationship(currentDepth: depth) else {
            throw RecursionLimitError()
        }
        guard let context = dto.managedObjectContext else {
            throw InvalidModel(dto)
        }
        try dto.isNotDeleted()

        let id = dto.id
        let cid = try? dto.cid.map { try ChannelId(cid: $0) }
        let text = dto.text
        let type = MessageType(rawValue: dto.type) ?? .regular
        let command = dto.command
        let createdAt = dto.createdAt.bridgeDate
        let locallyCreatedAt = dto.locallyCreatedAt?.bridgeDate
        let updatedAt = dto.updatedAt.bridgeDate
        let deletedAt = dto.deletedAt?.bridgeDate
        let arguments = dto.args
        let parentMessageId = dto.parentMessageId
        let showReplyInChannel = dto.showReplyInChannel
        let replyCount = Int(dto.replyCount)
        let isBounced = dto.isBounced
        let isSilent = dto.isSilent
        let isShadowed = dto.isShadowed
        let reactionScores = dto.reactionScores.mapKeys { MessageReactionType(rawValue: $0) }
        let reactionCounts = dto.reactionCounts.mapKeys { MessageReactionType(rawValue: $0) }
        let reactionGroups = dto.reactionGroups.asModel()
        let translations = dto.translations?.mapKeys { TranslationLanguage(languageCode: $0) }
        let originalLanguage = dto.originalLanguage.map(TranslationLanguage.init)
        let moderationDetails = dto.moderationDetails.map { MessageModerationDetails(fromDTO: $0) }
        let textUpdatedAt = dto.textUpdatedAt?.bridgeDate
        let chatClientConfig = context.chatClientConfig

        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: dto.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for Message with id: <\(dto.id)>, using default value instead. Error: \(error)"
            )
            extraData = [:]
        }

        let localState = dto.localMessageState
        let isFlaggedByCurrentUser = dto.flaggedBy != nil

        let pinDetails: MessagePinDetails?
        if dto.pinned,
           let pinnedAt = dto.pinnedAt,
           let pinnedBy = dto.pinnedBy {
            pinDetails = try .init(
                pinnedAt: pinnedAt.bridgeDate,
                pinnedBy: pinnedBy.asModel(),
                expiresAt: dto.pinExpires?.bridgeDate
            )
        } else {
            pinDetails = nil
        }
        
        let poll = try? dto.poll?.asModel()
        let location = try? dto.location?.asModel()

        let currentUserReactions: Set<ChatMessageReaction>
        let isSentByCurrentUser: Bool
        if let currentUser = context.currentUser {
            isSentByCurrentUser = currentUser.user.id == dto.user.id
            if !dto.ownReactions.isEmpty {
                currentUserReactions = Set(
                    MessageReactionDTO
                        .loadReactions(ids: dto.ownReactions, context: context)
                        .compactMap { try? $0.asModel() }
                )
            } else {
                currentUserReactions = []
            }
        } else {
            isSentByCurrentUser = false
            currentUserReactions = []
        }

        let latestReactions: Set<ChatMessageReaction> = {
            guard !dto.latestReactions.isEmpty else { return Set() }
            return Set(
                MessageReactionDTO
                    .loadReactions(ids: dto.latestReactions, context: context)
                    .compactMap { try? $0.asModel() }
            )
        }()

        let threadParticipants = dto.threadParticipants.array
            .compactMap { $0 as? UserDTO }
            .compactMap { try? $0.asModel() }

        let mentionedUsers = Set(dto.mentionedUsers.compactMap { try? $0.asModel() })

        let author = try dto.user.asModel()
        let _attachments = dto.attachments
            .compactMap { $0.asAnyModel() }
            .sorted { $0.id.index < $1.id.index }

        let latestReplies: [ChatMessage] = {
            guard dto.replyCount > 0 else { return [] }
            return dto.replies
                .sorted(by: { $0.createdAt.bridgeDate > $1.createdAt.bridgeDate })
                .prefix(5)
                .compactMap { try? ChatMessage(fromDTO: $0, depth: depth) }
        }()

        let quotedMessage = try? dto.quotedMessage?.relationshipAsModel(depth: depth)

        let draftReply = try? dto.draftReply?.relationshipAsModel(depth: depth)

        let readBy = Set(dto.reads.compactMap { try? $0.user.asModel() })

        let message = ChatMessage(
            id: id,
            cid: cid,
            text: text,
            type: type,
            command: command,
            createdAt: createdAt,
            locallyCreatedAt: locallyCreatedAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            arguments: arguments,
            parentMessageId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            replyCount: replyCount,
            extraData: extraData,
            quotedMessage: quotedMessage,
            isBounced: isBounced,
            isSilent: isSilent,
            isShadowed: isShadowed,
            reactionScores: reactionScores,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            author: author,
            mentionedUsers: mentionedUsers,
            threadParticipants: threadParticipants,
            attachments: _attachments,
            latestReplies: latestReplies,
            localState: localState,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            latestReactions: latestReactions,
            currentUserReactions: currentUserReactions,
            isSentByCurrentUser: isSentByCurrentUser,
            pinDetails: pinDetails,
            translations: translations,
            originalLanguage: originalLanguage,
            moderationDetails: moderationDetails,
            readBy: readBy,
            poll: poll,
            textUpdatedAt: textUpdatedAt,
            draftReply: draftReply.map(DraftMessage.init),
            reminder: dto.reminder.map { .init(
                remindAt: $0.remindAt?.bridgeDate,
                createdAt: $0.createdAt.bridgeDate,
                updatedAt: $0.updatedAt.bridgeDate
            ) },
            sharedLocation: location
        )

        if let transformer = chatClientConfig?.modelsTransformer {
            self = transformer.transform(message: message)
            return
        }

        self = message
    }

    // swiftlint:enable function_body_length
}

extension ClientError {
    final class CurrentUserDoesNotExist: ClientError {
        override var localizedDescription: String {
            "There is no `CurrentUserDTO` instance in the DB."
                + "Make sure to call `client.currentUserController.reloadUserIfNeeded()`"
        }
    }

    final class CurrentUserDoesNotHaveDeviceRegistered: ClientError {
        override var localizedDescription: String {
            "There is no `DeviceDTO` instance in the DB."
                + "Make sure to call `client.currentUserController.addDevice()`"
        }
    }

    final class MessagePayloadSavingFailure: ClientError {}

    final class ChannelDoesNotExist: ClientError {
        init(cid: ChannelId) {
            super.init("There is no `ChannelDTO` instance in the DB matching cid: \(cid).")
        }
    }
}
