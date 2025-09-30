//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelDTO)
class ChannelDTO: NSManagedObject {
    // The cid without the channel type.
    @NSManaged var id: String?
    // The channel id which includes channelType:channelId.
    @NSManaged var cid: String
    @NSManaged var name: String?
    @NSManaged var imageURL: URL?
    @NSManaged var typeRawValue: String
    @NSManaged var extraData: Data
    @NSManaged var config: ChannelConfigDTO
    @NSManaged var ownCapabilities: [String]

    @NSManaged var createdAt: DBDate
    @NSManaged var deletedAt: DBDate?
    @NSManaged var defaultSortingAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var lastMessageAt: DBDate?

    // The oldest message of the channel we have locally coming from a regular channel query.
    // This property only lives locally, and it is useful to filter out older pinned/quoted messages
    // that do not belong to the regular channel query.
    @NSManaged var oldestMessageAt: DBDate?

    // Used for paginating newer messages while jumping to a mid-page.
    // We want to avoid new messages being inserted in the UI if we are in a mid-page.
    @NSManaged var newestMessageAt: DBDate?

    // This field is also used to implement the `clearHistory` option when hiding the channel.
    @NSManaged var truncatedAt: DBDate?

    @NSManaged var isDisabled: Bool
    @NSManaged var isHidden: Bool

    @NSManaged var watcherCount: Int64
    @NSManaged var memberCount: Int64
    @NSManaged var messageCount: NSNumber?

    @NSManaged var isFrozen: Bool
    @NSManaged var cooldownDuration: Int
    @NSManaged var team: String?
    
    @NSManaged var isBlocked: Bool
    
    @NSManaged var pushPreference: PushPreferenceDTO?

    // MARK: - Queries

    // The channel list queries the channel is a part of
    @NSManaged var queries: Set<ChannelListQueryDTO>

    // MARK: - Relationships

    @NSManaged var createdBy: UserDTO?
    @NSManaged var members: Set<MemberDTO>
    @NSManaged var threads: Set<ThreadDTO>

    /// If the current user is a member of the channel, this is their MemberDTO
    @NSManaged var membership: MemberDTO?
    @NSManaged var currentlyTypingUsers: Set<UserDTO>
    @NSManaged var messages: Set<MessageDTO>
    @NSManaged var pinnedMessages: Set<MessageDTO>
    @NSManaged var pendingMessages: Set<MessageDTO>
    @NSManaged var reads: Set<ChannelReadDTO>

    /// Helper properties used for sorting channels with unread counts of the current user.
    @NSManaged var currentUserUnreadMessagesCount: Int32
    @NSManaged var hasUnreadSorting: Int16

    @NSManaged var watchers: Set<UserDTO>
    @NSManaged var memberListQueries: Set<ChannelMemberListQueryDTO>
    @NSManaged var previewMessage: MessageDTO?
    @NSManaged var draftMessage: MessageDTO?
    @NSManaged var activeLiveLocations: Set<SharedLocationDTO>

    /// If the current channel is muted by the current user, `mute` contains details.
    @NSManaged var mute: ChannelMuteDTO?

    override func willSave() {
        super.willSave()

        guard !isDeleted else {
            return
        }

        // Update the unreadMessagesCount for the current user.
        // At the moment this computed property is used for `hasUnread` and `unreadCount` automatic channel list filtering.
        if let currentUserId = managedObjectContext?.currentUser?.user.id {
            let currentUserUnread = reads.first(where: { $0.user.id == currentUserId })
            let newUnreadCount = currentUserUnread?.unreadMessageCount ?? 0
            if newUnreadCount != currentUserUnreadMessagesCount {
                currentUserUnreadMessagesCount = newUnreadCount
                hasUnreadSorting = newUnreadCount > 0 ? 1 : 0
            }
        }

        // Change to the `truncatedAt` value have effect on messages, we need to mark them dirty manually
        // to triggers related FRC updates
        if changedValues().keys.contains("truncatedAt") {
            messages
                .filter { !$0.hasChanges }
                .forEach {
                    // Simulate an update
                    $0.willChangeValue(for: \.id)
                    $0.didChangeValue(for: \.id)
                }

            // When truncating the channel, we need to reset the newestMessageAt so that
            // the channel can render newer messages in the UI.
            if newestMessageAt != nil {
                newestMessageAt = nil
            }
        }
        
        // Update the date for sorting every time new message in this channel arrive.
        // This will ensure that the channel list is updated/sorted when new message arrives.
        // Note: If a channel is truncated, the server will update the lastMessageAt to a minimum value, and not remove it.
        // So, if lastMessageAt is nil or is equal to distantPast, we need to fallback to createdAt.
        var lastDate = lastMessageAt ?? createdAt
        if lastDate.bridgeDate <= .distantPast {
            lastDate = createdAt
        }
        if lastDate != defaultSortingAt {
            defaultSortingAt = lastDate
        }
    }

    /// The fetch request that returns all existed channels from the database
    static var allChannelsFetchRequest: NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChannelDTO.updatedAt, ascending: false)]
        return request
    }

    static func fetchRequest(for cid: ChannelId) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        ChannelDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChannelDTO.updatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "cid == %@", cid.rawValue)
        return request
    }

    static func load(cid: ChannelId, context: NSManagedObjectContext) -> ChannelDTO? {
        let request = fetchRequest(for: cid)
        return load(by: request, context: context).first
    }

    static func load(cids: [ChannelId], context: NSManagedObjectContext) -> [ChannelDTO] {
        guard !cids.isEmpty else { return [] }
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        ChannelDTO.applyPrefetchingState(to: request)
        request.predicate = NSPredicate(format: "cid IN %@", cids)
        return load(by: request, context: context)
    }

    static func loadOrCreate(cid: ChannelId, context: NSManagedObjectContext, cache: PreWarmedCache?) -> ChannelDTO {
        if let cachedObject = cache?.model(for: cid.rawValue, context: context, type: ChannelDTO.self) {
            return cachedObject
        }

        let request = fetchRequest(for: cid)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.cid = cid.rawValue
        return new
    }
}

extension ChannelDTO {
    override class func prefetchedRelationshipKeyPaths() -> [String] {
        [
            KeyPath.string(\ChannelDTO.currentlyTypingUsers),
            KeyPath.string(\ChannelDTO.pinnedMessages),
            KeyPath.string(\ChannelDTO.messages),
            KeyPath.string(\ChannelDTO.members),
            KeyPath.string(\ChannelDTO.reads),
            KeyPath.string(\ChannelDTO.watchers)
        ]
    }
}

// MARK: - Reset Ephemeral Values

extension ChannelDTO: EphemeralValuesContainer {
    static func resetEphemeralValuesBatchRequests() -> [NSBatchUpdateRequest] {
        []
    }
    
    static func resetEphemeralRelationshipValues(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.predicate = NSPredicate(format: "watchers.@count > 0 OR currentlyTypingUsers.@count > 0")
        let channels = load(by: request, context: context)
        channels.forEach { channel in
            channel.resetEphemeralValues()
        }
    }
    
    func resetEphemeralValues() {
        currentlyTypingUsers.removeAll()
        watchers.removeAll()
        watcherCount = 0
    }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
    func saveChannelList(
        payload: ChannelListPayload,
        query: ChannelListQuery?
    ) -> [ChannelDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)

        // The query will be saved during `saveChannel` call
        // but in case this query does not have any channels,
        // the query won't be saved, which will cause any future
        // channels to not become linked to this query
        if let query = query {
            _ = saveQuery(query: query)
        }

        return payload.channels.compactMapLoggingError { channelPayload in
            try saveChannel(payload: channelPayload, query: query, cache: cache)
        }
    }

    func saveChannel(
        payload: ChannelDetailPayload,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO {
        let dto = ChannelDTO.loadOrCreate(cid: payload.cid, context: self, cache: cache)

        dto.name = payload.name
        dto.imageURL = payload.imageURL
        do {
            dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        } catch {
            log.error(
                "Failed to decode extra payload for Channel with cid: <\(dto.cid)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }
        dto.typeRawValue = payload.typeRawValue
        dto.id = payload.cid.id
        dto.config = payload.config.asDTO(context: self, cid: dto.cid)
        if let ownCapabilities = payload.ownCapabilities {
            dto.ownCapabilities = ownCapabilities
        }
        dto.createdAt = payload.createdAt.bridgeDate
        dto.deletedAt = payload.deletedAt?.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.defaultSortingAt = (payload.lastMessageAt ?? payload.createdAt).bridgeDate
        dto.lastMessageAt = payload.lastMessageAt?.bridgeDate
        dto.memberCount = Int64(clamping: payload.memberCount)
        
        if let messageCount = payload.messageCount {
            dto.messageCount = NSNumber(value: messageCount)
        }

        // Because `truncatedAt` is used, client side, for both truncation and channel hiding cases, we need to avoid using the
        // value returned by the Backend in some cases.
        //
        // Whenever our Backend is not returning a value for `truncatedAt`, we simply do nothing. It is possible that our
        // DTO already has a value for it if it has been hidden in the past, but we are not touching it.
        //
        // Whenever we do receive a value from our Backend, we have 2 options:
        //  1. If we don't have a value for `truncatedAt` in the DTO -> We set the date from the payload
        //  2. If we have a value for `truncatedAt` in the DTO -> We pick the latest date.
        if let newTruncatedAt = payload.truncatedAt {
            let canUpdateTruncatedAt = dto.truncatedAt.map { $0.bridgeDate < newTruncatedAt } ?? true
            if canUpdateTruncatedAt {
                dto.truncatedAt = newTruncatedAt.bridgeDate
            }
        }

        dto.isDisabled = payload.isDisabled
        dto.isFrozen = payload.isFrozen
        
        // Backend only returns a boolean
        // for blocked 1:1 channels on channel list query
        if let isBlocked = payload.isBlocked {
            dto.isBlocked = isBlocked
        }

        // Backend only returns a boolean for hidden state
        // on channel query and channel list query
        if let isHidden = payload.isHidden {
            dto.isHidden = isHidden
        }

        dto.cooldownDuration = payload.cooldownDuration
        dto.team = payload.team

        if let createdByPayload = payload.createdBy {
            let creatorDTO = try saveUser(payload: createdByPayload)
            dto.createdBy = creatorDTO
        }

        try payload.members?.forEach { memberPayload in
            let member = try saveMember(payload: memberPayload, channelId: payload.cid, query: nil, cache: cache)
            dto.members.insert(member)
        }

        if let query = query {
            let queryDTO = saveQuery(query: query)
            queryDTO.channels.insert(dto)
        }

        return dto
    }

    func saveChannel(
        payload: ChannelPayload,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO {
        let dto = try saveChannel(payload: payload.channel, query: query, cache: cache)

        // Save reads (note that returned reads are for currently fetched members)
        let reads = Set(
            try payload.channelReads.map {
                try saveChannelRead(payload: $0, for: payload.channel.cid, cache: cache)
            }
        )
        dto.reads.formUnion(reads)
        
        try payload.messages.forEach { _ = try saveMessage(payload: $0, channelDTO: dto, syncOwnReactions: true, cache: cache) }
        
        var pendingMessages = Set<MessageDTO>()
        try payload.pendingMessages?.forEach {
            let pending = try saveMessage(
                payload: $0,
                channelDTO: dto,
                syncOwnReactions: true,
                cache: cache
            )
            pendingMessages.insert(pending)
        }
                
        dto.pendingMessages = pendingMessages
        
        // Recalculate reads for existing messages (saveMessage updates it for messages in the payload)
        let channelReadDTOs = dto.reads
        let currentUserId = currentUser?.user.id
        let payloadMessageIds = Set(payload.messages.map(\.id) + (payload.pendingMessages?.map(\.id) ?? []))
        for message in dto.messages {
            guard message.user.id == currentUserId else { continue }
            guard !payloadMessageIds.contains(message.id) else { continue }
            message.updateReadBy(withChannelReads: channelReadDTOs)
        }
        
        if dto.needsPreviewUpdate(payload) {
            dto.previewMessage = preview(for: payload.channel.cid)
        }

        dto.updateOldestMessageAt(payload: payload)

        if let draftMessage = payload.draft {
            dto.draftMessage = try saveDraftMessage(payload: draftMessage, for: payload.channel.cid, cache: nil)
        } else {
            /// If the payload does not contain a draft message, we should
            /// delete the existing draft message if it exists.
            if let draftMessage = dto.draftMessage {
                deleteDraftMessage(in: payload.channel.cid, threadId: draftMessage.parentMessageId)
            }
        }

        dto.activeLiveLocations = Set(try payload.activeLiveLocations.map {
            try saveLocation(payload: $0, cache: cache)
        })

        try payload.pinnedMessages.forEach {
            _ = try saveMessage(payload: $0, channelDTO: dto, syncOwnReactions: true, cache: cache)
        }
        
        // Save push preference
        if let pushPreference = payload.pushPreference {
            dto.pushPreference = try savePushPreference(
                id: payload.channel.cid.rawValue,
                payload: pushPreference
            )
        }

        // Note: membership payload should be saved before all the members
        if let membership = payload.membership {
            let membershipDTO = try saveMember(payload: membership, channelId: payload.channel.cid, query: nil, cache: cache)
            dto.membership = membershipDTO
        } else {
            dto.membership = nil
        }
        
        // Sometimes, `members` are not part of `ChannelDetailPayload` so they need to be saved here too.
        try payload.members.forEach {
            let member = try saveMember(payload: $0, channelId: payload.channel.cid, query: nil, cache: cache)
            dto.members.insert(member)
        }

        dto.watcherCount = Int64(clamping: payload.watcherCount ?? 0)

        if let watchers = payload.watchers {
            // We don't call `removeAll` on watchers since user could've requested
            // a different page
            try watchers.forEach {
                let user = try saveUser(payload: $0)
                dto.watchers.insert(user)
            }
        }
        // We don't reset `watchers` array if it's missing
        // since that can mean that user didn't request watchers
        // This is done in `ChannelUpdater.channelWatchers` func

        return dto
    }

    func channel(cid: ChannelId) -> ChannelDTO? {
        ChannelDTO.load(cid: cid, context: self)
    }

    func delete(query: ChannelListQuery) {
        guard let dto = channelListQuery(filterHash: query.filter.filterHash) else { return }

        delete(dto)
    }

    func removeChannels(cids: Set<ChannelId>) {
        let channels = ChannelDTO.load(cids: Array(cids), context: self)
        channels.forEach(delete)
    }
}

// To get the data from the DB

extension ChannelDTO {
    static func channelListFetchRequest(
        query: ChannelListQuery,
        chatClientConfig: ChatClientConfig
    ) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        ChannelDTO.applyPrefetchingState(to: request)

        // Fetch results controller requires at least one sorting descriptor.
        var sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        
        // For consistent order we need to have a sort descriptor which breaks ties
        if !sortDescriptors.isEmpty, !sortDescriptors.contains(where: { $0.key == ChannelListSortingKey.updatedAt.localKey }) {
            if let tieBreaker = ChannelListSortingKey.updatedAt.sortDescriptor(isAscending: false) {
                sortDescriptors.append(tieBreaker)
            }
        }
        
        request.sortDescriptors = sortDescriptors.isEmpty ? [ChannelListSortingKey.defaultSortDescriptor] : sortDescriptors

        let matchingQuery = NSPredicate(format: "ANY queries.filterHash == %@", query.filter.filterHash)
        let notDeleted = NSPredicate(format: "deletedAt == nil")

        var subpredicates: [NSPredicate] = [
            matchingQuery, notDeleted
        ]

        // If a hidden filter is not provided, we add a default hidden filter == 0.
        // The backend appends a `hidden: false` filter when it's not specified, so we need to do the same.
        // Additionally we also check for blocked filter. Only if blocked or hidden filters are not provider,
        // we add default hidden filter.
        if query.filter.hiddenFilterValue == nil && query.filter.blockedFilterValue == nil {
            subpredicates.append(NSPredicate(format: "\(#keyPath(ChannelDTO.isHidden)) == 0"))
        }

        if chatClientConfig.isChannelAutomaticFilteringEnabled, let filterPredicate = query.filter.predicate {
            subpredicates.append(filterPredicate)
        }

        request.predicate = NSCompoundPredicate(type: .and, subpredicates: subpredicates)
        request.fetchLimit = query.pagination.pageSize
        request.fetchBatchSize = query.pagination.pageSize
        return request
    }
    
    static func directMessageChannel(participantId: UserId, context: NSManagedObjectContext) -> ChannelDTO? {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        ChannelDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChannelDTO.updatedAt, ascending: false)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "cid CONTAINS ':!members'"),
            NSPredicate(format: "members.@count == 2"),
            NSPredicate(format: "ANY members.user.id == %@", participantId)
        ])
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

extension ChannelDTO {
    /// Snapshots the current state of `ChannelDTO` and returns an immutable model object from it.
    func asModel() throws -> ChatChannel {
        try .create(fromDTO: self, depth: 0)
    }

    /// Snapshots the current state of `ChannelDTO` and returns an immutable model object from it if the dependency depth
    /// limit has not been reached
    func relationshipAsModel(depth: Int) throws -> ChatChannel? {
        do {
            return try .create(fromDTO: self, depth: depth + 1)
        } catch {
            if error is RecursionLimitError { return nil }
            throw error
        }
    }
}

extension ChatChannel {
    /// Create a ChannelModel struct from its DTO
    fileprivate static func create(fromDTO dto: ChannelDTO, depth: Int) throws -> ChatChannel {
        guard StreamRuntimeCheck._canFetchRelationship(currentDepth: depth) else {
            throw RecursionLimitError()
        }

        try dto.isNotDeleted()

        guard let cid = try? ChannelId(cid: dto.cid),
              let context = dto.managedObjectContext,
              let clientConfig = context.chatClientConfig else {
            throw InvalidModel(dto)
        }

        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: dto.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for Channel with cid: <\(dto.cid)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = [:]
        }
        
        let sortedMessageDTOs = dto.messages.sorted(by: { $0.createdAt.bridgeDate > $1.createdAt.bridgeDate })
        let reads: [ChatChannelRead] = try dto.reads.map { try $0.asModel() }
        let unreadCount: ChannelUnreadCount = {
            guard let currentUserDTO = context.currentUser else {
                return .noUnread
            }
            let currentUserRead = reads.first(where: { $0.user.id == currentUserDTO.user.id })
            let allUnreadMessages = currentUserRead?.unreadMessagesCount ?? 0
            // Therefore, no unread messages with mentions and we can skip the fetch
            if allUnreadMessages == 0 {
                return .noUnread
            }
            let unreadMentionsCount = sortedMessageDTOs
                .prefix(allUnreadMessages)
                .filter { $0.mentionedUsers.contains(currentUserDTO.user) }
                .count
            return ChannelUnreadCount(
                messages: allUnreadMessages,
                mentions: unreadMentionsCount
            )
        }()

        let latestMessages: [ChatMessage] = {
            var messages = sortedMessageDTOs
                .prefix(clientConfig.localCaching.chatChannel.latestMessagesLimit)
                .compactMap { try? $0.relationshipAsModel(depth: depth) }
            if let oldest = dto.oldestMessageAt?.bridgeDate {
                messages = messages.filter { $0.createdAt >= oldest }
            }
            if let truncated = dto.truncatedAt?.bridgeDate {
                messages = messages.filter { $0.createdAt >= truncated }
            }
            return messages
        }()

        let latestMessageFromUser: ChatMessage? = {
            guard let currentUserId = context.currentUser?.user.id else { return nil }
            return try? sortedMessageDTOs
                .first(where: { messageDTO in
                    guard messageDTO.user.id == currentUserId else { return false }
                    guard messageDTO.localMessageState == nil else { return false }
                    return messageDTO.type != MessageType.ephemeral.rawValue
                })?
                .relationshipAsModel(depth: depth)
        }()
        
        let watchers = dto.watchers
            .sorted { lhs, rhs in
                let lhsActivity = lhs.lastActivityAt?.bridgeDate ?? .distantPast
                let rhsActivity = rhs.lastActivityAt?.bridgeDate ?? .distantPast
                if lhsActivity == rhsActivity {
                    return lhs.id > rhs.id
                }
                return lhsActivity > rhsActivity
            }
            .prefix(clientConfig.localCaching.chatChannel.lastActiveWatchersLimit)
            .compactMap { try? $0.asModel() }
        
        let members = dto.members
            .sorted { lhs, rhs in
                let lhsActivity = lhs.user.lastActivityAt?.bridgeDate ?? .distantPast
                let rhsActivity = rhs.user.lastActivityAt?.bridgeDate ?? .distantPast
                if lhsActivity == rhsActivity {
                    return lhs.id > rhs.id
                }
                return lhsActivity > rhsActivity
            }
            .prefix(clientConfig.localCaching.chatChannel.lastActiveMembersLimit)
            .compactMap { try? $0.asModel() }

        let muteDetails: MuteDetails? = {
            guard let mute = dto.mute else { return nil }
            return .init(
                createdAt: mute.createdAt.bridgeDate,
                updatedAt: mute.updatedAt.bridgeDate,
                expiresAt: mute.expiresAt?.bridgeDate
            )
        }()
        let membership = try dto.membership.map { try $0.asModel() }
        let pinnedMessages = dto.pinnedMessages.compactMap { try? $0.relationshipAsModel(depth: depth) }
        let pendingMessages = dto.pendingMessages.compactMap { try? $0.relationshipAsModel(depth: depth) }
        let previewMessage = try? dto.previewMessage?.relationshipAsModel(depth: depth)
        let draftMessage = try? dto.draftMessage?.relationshipAsModel(depth: depth)
        let typingUsers = Set(dto.currentlyTypingUsers.compactMap { try? $0.asModel() })
        let activeLiveLocations = try dto.activeLiveLocations.map { try $0.asModel() }
        
        let pushPreference = try dto.pushPreference?.asModel()

        let channel = try ChatChannel(
            cid: cid,
            name: dto.name,
            imageURL: dto.imageURL,
            lastMessageAt: dto.lastMessageAt?.bridgeDate,
            createdAt: dto.createdAt.bridgeDate,
            updatedAt: dto.updatedAt.bridgeDate,
            deletedAt: dto.deletedAt?.bridgeDate,
            truncatedAt: dto.truncatedAt?.bridgeDate,
            isHidden: dto.isHidden,
            createdBy: dto.createdBy?.asModel(),
            config: dto.config.asModel(),
            ownCapabilities: Set(dto.ownCapabilities.compactMap(ChannelCapability.init(rawValue:))),
            isFrozen: dto.isFrozen,
            isDisabled: dto.isDisabled,
            isBlocked: dto.isBlocked,
            lastActiveMembers: members,
            membership: membership,
            currentlyTypingUsers: typingUsers,
            lastActiveWatchers: watchers,
            team: dto.team,
            unreadCount: unreadCount,
            watcherCount: Int(dto.watcherCount),
            memberCount: Int(dto.memberCount),
            messageCount: dto.messageCount?.intValue,
            reads: reads,
            cooldownDuration: Int(dto.cooldownDuration),
            extraData: extraData,
            latestMessages: latestMessages,
            lastMessageFromCurrentUser: latestMessageFromUser,
            pinnedMessages: pinnedMessages,
            pendingMessages: pendingMessages,
            muteDetails: muteDetails,
            previewMessage: previewMessage,
            draftMessage: draftMessage.map(DraftMessage.init),
            activeLiveLocations: activeLiveLocations,
            pushPreference: pushPreference
        )

        if let transformer = clientConfig.modelsTransformer {
            return transformer.transform(channel: channel)
        }

        return channel
    }
}

// MARK: - Helpers

extension ChannelDTO {
    func cleanAllMessagesExcludingLocalOnly() {
        messages = messages.filter { $0.isLocalOnly }
    }

    /// Updates the `oldestMessageAt` of the channel. It should only update if the current `oldestMessageAt` is not older already.
    /// This property is useful to filter out older pinned/quoted messages that do not belong to the regular channel query,
    /// but are already in the database.
    func updateOldestMessageAt(payload: ChannelPayload) {
        guard let payloadOldestMessageAt = payload.messages.map(\.createdAt).min() else { return }
        let isOlderThanCurrentOldestMessage = payloadOldestMessageAt < (oldestMessageAt?.bridgeDate ?? Date.distantFuture)
        if isOlderThanCurrentOldestMessage {
            oldestMessageAt = payloadOldestMessageAt.bridgeDate
        }
    }

    /// Returns `true` if the payload holds messages sent after the current channel preview.
    func needsPreviewUpdate(_ payload: ChannelPayload) -> Bool {
        guard let preview = previewMessage else {
            return true
        }

        guard let newestMessage = payload.newestMessage else {
            return false
        }

        return newestMessage.createdAt > preview.createdAt.bridgeDate
    }
}
