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

    // Whether `scheduledAt` was changed locally and is not on the server yet.
    @NSManaged var hasPendingScheduledAt: Bool

    // Whether the message is sent right away, once its local changes and attachments are on the server.
    @NSManaged var isPendingSendNow: Bool

    // Why the latest local changes could not be sent to the server, from the error of the server.
    @NSManaged var syncErrorReason: String?
    @NSManaged var syncErrorMessage: String?
    // Whether the error comes from the local device, which never got a response from the server.
    @NSManaged var isSyncErrorLocal: Bool

    // The quoted message is not always available locally, so its id is kept.
    @NSManaged var quotedMessageId: String?

    // The backend leaves the channel out when it is gone or can't be read, so the last known one is kept.
    @NSManaged var channelName: String?
    @NSManaged var channelImageURL: URL?
    @NSManaged var channelMemberCount: Int64

    // Relationships

    // The content of the message, with its local state and attachments, like any other message.
    @NSManaged var message: MessageDTO?

    // The channel of the message, when it is saved locally.
    @NSManaged var channel: ChannelDTO?
    @NSManaged var channelMembers: Set<MemberDTO>

    override func willSave() {
        super.willSave()

        guard !isDeleted else { return }

        let newIsPending = ScheduledMessageStatus(
            localState: message?.localMessageState,
            serverStatus: status,
            isPendingSendNow: isPendingSendNow
        ) != .failed
        if isPending != newIsPending {
            isPending = newIsPending
        }
        // The channel observers observe the channels, so changes of its scheduled messages are propagated to them.
        if let channel, !channel.hasChanges, !channel.isDeleted {
            channel.cid = channel.cid
        }
    }

    /// Returns a fetch request for the scheduled message with the provided id.
    static func fetchRequest(id: String) -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: true)]
        return request
    }

    /// Returns a fetch request for the scheduled messages of the channel with the provided id.
    static func fetchRequest(cid: ChannelId) -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.predicate = NSPredicate(format: "cid == %@", cid.rawValue)
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
        // Without a sorting, pending messages come first and failed ones after, each sorted by `scheduledAt`, like on
        // the server.
        if sortDescriptors.isEmpty {
            sortDescriptors = [
                NSSortDescriptor(keyPath: \ScheduledMessageDTO.isPending, ascending: false),
                NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: true)
            ]
        }
        // Messages sent at the same time keep the order of the server.
        sortDescriptors.append(NSSortDescriptor(keyPath: \ScheduledMessageDTO.id, ascending: true))
        request.sortDescriptors = sortDescriptors

        if let filter = query.filter, let predicate = filter.predicate {
            request.predicate = predicate
        }

        return request
    }

    /// Returns a fetch request for the scheduled messages with local changes to send to the server, or to send right
    /// away once their changes are sent, when all their attachments are uploaded.
    static func pendingRequestsFetchRequest() -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledMessageDTO.createdAt, ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(
                    format: "message.localMessageStateRaw IN %@",
                    [LocalMessageState.pendingSend.rawValue, LocalMessageState.pendingSync.rawValue]
                ),
                NSPredicate(format: "isPendingSendNow == YES AND message.localMessageStateRaw == nil")
            ]),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(
                    format: "SUBQUERY(message.attachments, $a, $a.localStateRaw == %@).@count == message.attachments.@count",
                    LocalAttachmentState.uploaded.rawValue
                ),
                NSPredicate(format: "SUBQUERY(message.attachments, $a, $a.localStateRaw == nil).@count == message.attachments.@count")
            ])
        ])
        return request
    }

    // The scheduled messages with an attachment that failed to upload, which the `MessageScheduler` never sends.
    static func failedUploadsFetchRequest() -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledMessageDTO.createdAt, ascending: true)]
        request.predicate = NSPredicate(
            format: "ANY message.attachments.localStateRaw == %@",
            LocalAttachmentState.uploadingFailed.rawValue
        )
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

    /// Whether the scheduled message was created locally and is not on the server yet.
    var isLocalOnly: Bool {
        switch message?.localMessageState {
        case .pendingSend, .sending, .sendingFailed:
            return true
        default:
            return false
        }
    }

    var isServerFailed: Bool {
        ScheduledMessageServerStatus(rawValue: status) == .failed && !hasLocalChanges
    }

    /// Whether the scheduled message has local changes the server does not have yet.
    var hasLocalChanges: Bool {
        switch message?.localMessageState {
        case .pendingSend, .sending, .pendingSync, .syncing, .syncingFailed:
            return true
        default:
            return false
        }
    }
}

extension NSManagedObjectContext: ScheduledMessageDatabaseSession {
    func createNewScheduledMessage(
        id: String,
        cid: ChannelId,
        content: ScheduledMessageContent,
        scheduledAt: Date
    ) throws -> ScheduledMessageDTO {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        try validateScheduledMessage(
            cid: cid,
            text: content.text,
            quotedMessageId: content.quotedMessageId,
            scheduledAt: scheduledAt,
            editing: nil,
            excludingId: id
        )

        let now = Date()
        let dto = ScheduledMessageDTO.loadOrCreate(id: id, context: self)
        dto.cid = cid.rawValue
        dto.status = ScheduledMessageServerStatus.scheduled.rawValue
        dto.failureReason = nil
        dto.syncErrorReason = nil
        dto.syncErrorMessage = nil
        dto.isSyncErrorLocal = false
        dto.scheduledAt = scheduledAt.bridgeDate
        dto.createdAt = now.bridgeDate
        dto.updatedAt = now.bridgeDate
        dto.quotedMessageId = content.quotedMessageId
        dto.channel = channel(cid: cid)
        if let channel = dto.channel {
            dto.channelName = channel.name
            dto.channelImageURL = channel.imageURL
            dto.channelMemberCount = channel.memberCount
            dto.channelMembers = channel.members
        }

        let message = contentMessage(of: dto)
        try saveContent(content, to: message, cid: cid, user: currentUserDTO.user)
        // Set when scheduling only, because the update request has no field for it.
        message.skipPush = content.skipPush
        message.locallyCreatedAt = now.bridgeDate
        message.createdAt = scheduledAt.bridgeDate
        message.updatedAt = now.bridgeDate
        message.localMessageState = .pendingSend

        return dto
    }

    func updateScheduledMessage(
        id: String,
        content: ScheduledMessageContent?,
        scheduledAt: Date?
    ) throws -> ScheduledMessageDTO {
        guard let dto = scheduledMessage(id: id), let message = dto.message else {
            throw ClientError.ScheduledMessageDoesNotExist(id: id)
        }
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        if dto.isServerFailed {
            throw ClientError.ScheduledMessageNotEditable(id: id)
        }
        let cid = try ChannelId(cid: dto.cid)
        try validateScheduledMessage(
            cid: cid,
            text: content?.text,
            quotedMessageId: content?.quotedMessageId,
            scheduledAt: scheduledAt,
            editing: id
        )

        if let content {
            // Without a thread, the message keeps the thread it was scheduled in.
            var content = content
            if content.parentId == nil {
                content.parentId = message.parentMessageId
                content.showReplyInChannel = message.showReplyInChannel
            }
            try saveContent(content, to: message, cid: cid, user: currentUserDTO.user)
            dto.quotedMessageId = content.quotedMessageId
        }
        if let scheduledAt {
            dto.scheduledAt = scheduledAt.bridgeDate
            message.createdAt = scheduledAt.bridgeDate
            dto.hasPendingScheduledAt = !dto.isLocalOnly
        }
        message.restartFailedUploads()
        dto.updatedAt = Date().bridgeDate
        dto.syncErrorReason = nil
        dto.syncErrorMessage = nil
        dto.isSyncErrorLocal = false
        message.updatedAt = dto.updatedAt
        // A message that is not on the server yet is scheduled with its latest content.
        message.localMessageState = dto.isLocalOnly ? .pendingSend : .pendingSync

        return dto
    }

    func validateScheduledMessage(
        cid: ChannelId?,
        text: String?,
        quotedMessageId: MessageId?,
        scheduledAt: Date?,
        editing id: String?
    ) throws {
        try validateScheduledMessage(
            cid: cid,
            text: text,
            quotedMessageId: quotedMessageId,
            scheduledAt: scheduledAt,
            editing: id,
            excludingId: nil
        )
    }

    func scheduledMessagesUsage(cid: ChannelId) throws -> ScheduledMessagesUsage {
        try scheduledMessagesUsage(cid: cid, excludingId: nil)
    }

    func saveScheduledMessage(payload: ScheduledMessageResponse) throws -> ScheduledMessageDTO {
        let cid = try ChannelId(cid: payload.cid)
        let dto = ScheduledMessageDTO.loadOrCreate(id: payload.id, context: self)

        dto.cid = cid.rawValue
        dto.status = payload.status.rawValue
        dto.failureReason = payload.failureReason?.rawValue
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        if dto.channel?.cid != cid.rawValue {
            dto.channel = channel(cid: cid)
        }
        if let channel = payload.channel {
            dto.channelName = channel.name
            dto.channelImageURL = channel.image.flatMap(URL.init(string:))
            dto.channelMemberCount = Int64(channel.memberCount)
            dto.channelMembers = try Set(channel.members.map { try saveMember(payload: $0, channelId: cid, query: nil, cache: nil) })
        }

        let message = contentMessage(of: dto)
        // Local changes win until they are sent to the server.
        guard !dto.hasLocalChanges else { return dto }

        let content = payload.message
        let user = try saveUser(payload: payload.user)
        dto.syncErrorReason = nil
        dto.syncErrorMessage = nil
        dto.isSyncErrorLocal = false
        dto.scheduledAt = payload.scheduledAt.bridgeDate
        dto.hasPendingScheduledAt = false
        dto.quotedMessageId = content.quotedMessageId

        message.cid = cid.rawValue
        message.text = content.text
        message.type = content.parentId == nil ? MessageType.regular.rawValue : MessageType.reply.rawValue
        message.parentMessageId = content.parentId
        message.showReplyInChannel = content.showInChannel ?? false
        do {
            message.extraData = try JSONEncoder.default.encode(content.custom)
        } catch {
            log.error("Failed to encode scheduled message extra data. Error: \(error)")
            message.extraData = nil
        }
        message.isSilent = content.silent ?? false
        message.user = user
        message.mentionedUserIds = content.mentionedUsers ?? []
        message.mentionedUsers = Set(message.mentionedUserIds.compactMap { self.user(id: $0) })
        message.mentionedHere = content.mentionedHere ?? false
        message.mentionedChannel = content.mentionedChannel ?? false
        message.mentionedGroupIds = content.mentionedGroupIds ?? []
        message.mentionedGroups = Set(message.mentionedGroupIds.compactMap { UserGroupDTO.load(id: $0, context: self) })
        message.mentionedRoles = content.mentionedRoles ?? []
        if let quotedMessage = content.quotedMessage {
            message.quotedMessage = try saveQuotedScheduledMessage(payload: quotedMessage)
        } else {
            message.quotedMessage = content.quotedMessageId.flatMap { MessageDTO.load(id: $0, context: self) }
        }
        message.poll = content.pollId.flatMap { try? poll(id: $0) }
        message.pinned = content.pinned ?? false
        message.pinnedBy = message.pinned ? user : nil
        message.pinnedAt = message.pinned ? payload.scheduledAt.bridgeDate : nil
        message.pinExpires = message.pinned ? content.pinExpires?.bridgeDate : nil
        message.createdAt = payload.scheduledAt.bridgeDate
        message.updatedAt = payload.updatedAt.bridgeDate

        let attachments = try (content.attachments ?? []).enumerated().map { index, attachment in
            try saveAttachment(payload: attachment, id: AttachmentId(cid: cid, messageId: message.id, index: index))
        }
        message.attachments.subtracting(attachments).forEach { delete($0) }
        message.attachments = Set(attachments)

        return dto
    }

    func saveScheduledMessages(payload: [ScheduledMessageResponse], cid: ChannelId) {
        payload.forEach { payload in
            do {
                _ = try saveScheduledMessage(payload: payload)
            } catch {
                log.error("Failed to save the scheduled message \(payload.id): \(error)")
            }
        }
        deleteScheduledMessages(notIn: Set(payload.map(\.id)), cid: cid)
    }

    func deleteScheduledMessages(notIn ids: Set<String>, cid: ChannelId?) {
        let request = cid.map(ScheduledMessageDTO.fetchRequest(cid:)) ?? ScheduledMessageDTO.scheduledMessagesFetchRequest(query: .init())
        ScheduledMessageDTO.load(by: request, context: self)
            .filter { !ids.contains($0.id) && !$0.isLocalOnly }
            .forEach { deleteScheduledMessage(id: $0.id) }
    }

    func scheduledMessage(id: String) -> ScheduledMessageDTO? {
        ScheduledMessageDTO.load(id: id, context: self)
    }

    func rescueScheduledMessagesStuckInSyncing() {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.predicate = NSPredicate(format: "message.localMessageStateRaw == %@", LocalMessageState.syncing.rawValue)
        ScheduledMessageDTO.load(by: request, context: self).forEach {
            $0.message?.localMessageState = .pendingSync
        }
    }

    func restartFailedUploadsOfPendingScheduledMessages() {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.predicate = NSPredicate(
            format: "message.localMessageStateRaw IN %@ AND ANY message.attachments.localStateRaw == %@",
            [LocalMessageState.pendingSend.rawValue, LocalMessageState.pendingSync.rawValue],
            LocalAttachmentState.uploadingFailed.rawValue
        )
        ScheduledMessageDTO.load(by: request, context: self).forEach {
            $0.message?.restartFailedUploads()
        }
    }

    func deleteScheduledMessage(id: String) {
        guard let dto = scheduledMessage(id: id) else { return }
        // The sent message can have the same id and reuse the content, it is kept then.
        if let message = dto.message, message.channel == nil {
            delete(message)
        }
        delete(dto)
    }

    private func contentMessage(of dto: ScheduledMessageDTO) -> MessageDTO {
        if let message = dto.message {
            return message
        }

        let message = MessageDTO.loadOrCreate(id: dto.id, context: self, cache: nil)
        message.reactionScores = [:]
        message.reactionCounts = [:]
        message.reactionGroups = []
        message.mentionedGroupIds = []
        message.mentionedRoles = []
        message.skipPush = false
        message.skipEnrichUrl = false
        message.isSilent = false
        dto.message = message
        return message
    }

    // The saves and `validateForScheduling` run the same checks, so they can't disagree. `nil` values are not checked.
    private func validateScheduledMessage(
        cid: ChannelId?,
        text: String?,
        quotedMessageId: MessageId?,
        scheduledAt: Date?,
        editing id: String?,
        excludingId: String?
    ) throws {
        guard currentUser != nil else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        var cid = cid
        var text = text
        var quotedMessageId = quotedMessageId
        var isNew = id == nil
        if let id {
            guard let dto = scheduledMessage(id: id), let message = dto.message else {
                throw ClientError.ScheduledMessageDoesNotExist(id: id)
            }
            cid = try ChannelId(cid: dto.cid)
            // A message the server failed to send is scheduled again as a new message.
            if dto.isServerFailed {
                isNew = true
            }
            // Without new content, the message keeps its own.
            if text == nil {
                text = isNew ? message.text : nil
                quotedMessageId = dto.quotedMessageId
            }
        }
        guard let cid else {
            throw ClientError.ChannelNotCreatedYet()
        }
        if let text {
            try validateCommand(text, cid: cid)
        }
        try validateQuotedMessage(quotedMessageId)
        if let scheduledAt {
            try validateScheduledAt(scheduledAt, cid: cid)
        }
        if isNew {
            try validateScheduledMessagesLimits(cid: cid, excludingId: excludingId)
        }
    }

    /// The server never schedules a slash command, which runs side effects or shows ephemeral output when it is sent,
    /// in a channel with commands. It is refused locally, so it is not saved and sent to fail.
    private func validateCommand(_ text: String, cid: ChannelId) throws {
        if text.hasPrefix("/"), (channel(cid: cid)?.config.commands.count ?? 0) > 0 {
            throw ClientError.ScheduledMessageHasACommand()
        }
    }

    /// The server rejects a date sooner than the minimum lead time of the app, or further ahead than the maximum lead
    /// time. It is refused locally when the channel config has the limit.
    private func validateScheduledAt(_ scheduledAt: Date, cid: ChannelId) throws {
        let config = channel(cid: cid)?.config
        if let minLeadTime = config?.scheduledMessagesMinLeadTime?.doubleValue, scheduledAt.timeIntervalSinceNow < minLeadTime {
            throw ClientError.ScheduledMessageIsTooSoon(minLeadTime: minLeadTime)
        }
        if let maxLeadTime = config?.scheduledMessagesMaxLeadTime?.doubleValue, scheduledAt.timeIntervalSinceNow > maxLeadTime {
            throw ClientError.ScheduledMessageIsTooFarAhead(maxLeadTime: maxLeadTime)
        }
    }

    /// The server rejects a new scheduled message once the current user has as many pending ones as the app allows,
    /// in the channel or in all channels. Failed messages don't count, except ones whose edit failed. It is refused
    /// locally when the channel config has the limits, counting the pending messages saved locally.
    private func validateScheduledMessagesLimits(cid: ChannelId, excludingId id: String?) throws {
        let usage = try scheduledMessagesUsage(cid: cid, excludingId: id)
        if let limit = usage.channelLimit, usage.channelCount >= limit {
            throw ClientError.ScheduledMessagesChannelLimitReached(limit: limit)
        }
        if let limit = usage.userLimit, usage.userCount >= limit {
            throw ClientError.ScheduledMessagesUserLimitReached(limit: limit)
        }
    }

    private func scheduledMessagesUsage(cid: ChannelId, excludingId id: String?) throws -> ScheduledMessagesUsage {
        let config = channel(cid: cid)?.config
        // The server still has a message whose edit failed.
        let pending = NSPredicate(
            format: "(isPending == YES OR message.localMessageStateRaw == %@) AND id != %@",
            LocalMessageState.syncingFailed.rawValue,
            id ?? ""
        )
        let channelRequest = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        channelRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            pending, NSPredicate(format: "cid == %@", cid.rawValue)
        ])
        let userRequest = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        userRequest.predicate = pending
        return ScheduledMessagesUsage(
            channelCount: try count(for: channelRequest),
            channelLimit: config?.scheduledMessagesMaxPerChannel?.intValue,
            userCount: try count(for: userRequest),
            userLimit: config?.scheduledMessagesMaxPerUser?.intValue
        )
    }

    private func saveContent(_ content: ScheduledMessageContent, to message: MessageDTO, cid: ChannelId, user: UserDTO) throws {
        message.cid = cid.rawValue
        message.text = content.text
        message.type = content.parentId == nil ? MessageType.regular.rawValue : MessageType.reply.rawValue
        message.parentMessageId = content.parentId
        message.showReplyInChannel = content.showReplyInChannel
        do {
            message.extraData = try JSONEncoder.default.encode(content.extraData)
        } catch {
            log.error("Failed to encode scheduled message extra data. Error: \(error)")
            message.extraData = nil
        }
        message.user = user
        message.mentionedUserIds = content.mentionedUserIds
        message.mentionedUsers = Set(content.mentionedUserIds.compactMap { self.user(id: $0) })
        message.mentionedHere = content.mentionedHere
        message.mentionedChannel = content.mentionedChannel
        message.mentionedGroupIds = content.mentionedGroupIds
        message.mentionedGroups = Set(content.mentionedGroupIds.compactMap { UserGroupDTO.load(id: $0, context: self) })
        message.mentionedRoles = content.mentionedRoles
        message.isSilent = content.isSilent
        message.quotedMessage = content.quotedMessageId.flatMap { MessageDTO.load(id: $0, context: self) }

        message.attachments.forEach { delete($0) }
        message.attachments = Set(
            try content.attachments.enumerated().map { index, attachment in
                try createNewAttachment(attachment: attachment, id: AttachmentId(cid: cid, messageId: message.id, index: index))
            }
        )
    }
}

// MARK: - Converting to domain model

extension ScheduledMessageDTO {
    /// Snapshots the current state of `ScheduledMessageDTO` and returns an immutable model object from it.
    func asModel() throws -> ScheduledMessage {
        try isNotDeleted()
        guard let message, managedObjectContext != nil else { throw InvalidModel(self) }
        let channelId = try ChannelId(cid: cid)
        let chatMessage = try message.asModel()
        let failure = modelFailure
        let localChannel = channelName == nil && channelImageURL == nil ? managedObjectContext?.channel(cid: channelId) : nil
        return ScheduledMessage(
            id: id,
            cid: channelId,
            channel: ScheduledMessageChannel(
                cid: channelId,
                name: channelName ?? localChannel?.name,
                imageURL: channelImageURL ?? localChannel?.imageURL,
                memberCount: Int(channelMemberCount),
                members: try channelMembers
                    .sorted { $0.memberCreatedAt.bridgeDate < $1.memberCreatedAt.bridgeDate }
                    .map { try $0.asModel() }
            ),
            message: chatMessage,
            quotedMessageId: quotedMessageId,
            scheduledAt: scheduledAt.bridgeDate,
            status: ScheduledMessageStatus(localState: message.localMessageState, serverStatus: status, isPendingSendNow: isPendingSendNow),
            failure: failure,
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt.bridgeDate
        )
    }
}

extension MessageDTO {
    func restartFailedUploads() {
        attachments
            .filter { $0.localState == .uploadingFailed }
            .forEach { $0.localState = .pendingUpload }
    }
}

private extension ScheduledMessageDTO {
    // The failure of the latest local changes wins, since it is the most recent.
    var modelFailure: ScheduledMessageFailure? {
        if [.sendingFailed, .syncingFailed].contains(message?.localMessageState) {
            if let syncErrorMessage, !isSyncErrorLocal {
                return .serverRejectedScheduling(.init(
                    reason: syncErrorReason.map(ScheduledMessageFailure.ServerRejection.Reason.init(rawValue:)),
                    message: syncErrorMessage
                ))
            }
            let hasFailedUpload = message?.attachments.contains { $0.localState == .uploadingFailed } == true
            return .localDeviceFailedScheduling(.init(
                reason: hasFailedUpload ? .attachmentUploadFailed : .requestFailed,
                message: hasFailedUpload ? nil : syncErrorMessage
            ))
        }
        if ScheduledMessageServerStatus(rawValue: status) == .failed {
            return .serverFailedPublishing(.init(
                reason: failureReason.map(ScheduledMessageFailureReason.init(rawValue:))
            ))
        }
        return nil
    }
}

extension DatabaseSession {
    /// The server sends a scheduled message with the checks of a live send, which can't quote a deleted message. It is
    /// refused locally when the quoted message is known to be deleted.
    func validateQuotedMessage(_ id: MessageId?) throws {
        guard let id, message(id: id)?.deletedAt != nil else { return }
        throw ClientError.ScheduledMessageQuotesADeletedMessage()
    }

    func scheduleFailedMessageAgain(
        id: String,
        content: ScheduledMessageContent?,
        scheduledAt: Date
    ) throws -> ScheduledMessageDTO {
        guard let dto = scheduledMessage(id: id), let message = dto.message else {
            throw ClientError.ScheduledMessageDoesNotExist(id: id)
        }
        try validateScheduledMessage(
            cid: nil,
            text: content?.text,
            quotedMessageId: content?.quotedMessageId,
            scheduledAt: scheduledAt,
            editing: id
        )
        let cid = try ChannelId(cid: dto.cid)
        var newContent = try content ?? ScheduledMessageContent(
            text: message.text,
            attachments: message.attachments
                .sorted { ($0.attachmentID?.index ?? 0) < ($1.attachmentID?.index ?? 0) }
                .map { AnyAttachmentPayload(type: $0.attachmentType, payload: try JSONDecoder.stream.decodeRawJSON(from: $0.data), localFileURL: nil) },
            mentionedUserIds: message.mentionedUserIds,
            mentionedHere: message.mentionedHere,
            mentionedChannel: message.mentionedChannel,
            mentionedGroupIds: message.mentionedGroupIds,
            mentionedRoles: message.mentionedRoles,
            quotedMessageId: dto.quotedMessageId,
            parentId: message.parentMessageId,
            showReplyInChannel: message.showReplyInChannel,
            isSilent: message.isSilent,
            extraData: JSONDecoder.stream.decodeRawJSON(from: message.extraData)
        )
        // Without a thread, the message keeps the thread it was scheduled in.
        if newContent.parentId == nil {
            newContent.parentId = message.parentMessageId
            newContent.showReplyInChannel = message.showReplyInChannel
        }
        newContent.skipPush = message.skipPush
        let new = try createNewScheduledMessage(id: .newUniqueId, cid: cid, content: newContent, scheduledAt: scheduledAt)
        new.channelName = new.channelName ?? dto.channelName
        new.channelImageURL = new.channelImageURL ?? dto.channelImageURL
        if new.channelMembers.isEmpty {
            new.channelMemberCount = dto.channelMemberCount
            new.channelMembers = dto.channelMembers
        }
        deleteScheduledMessage(id: id)
        return new
    }
}
