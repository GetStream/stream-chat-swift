//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelDTO)
class ChannelDTO: NSManagedObject {
    @NSManaged var cid: String
    @NSManaged var name: String?
    @NSManaged var imageURL: URL?
    @NSManaged var typeRawValue: String
    @NSManaged var extraData: Data
    @NSManaged var config: ChannelConfigDTO
    
    @NSManaged var createdAt: DBDate
    @NSManaged var deletedAt: DBDate?
    @NSManaged var defaultSortingAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var lastMessageAt: DBDate?

    // The oldest message of the channel we have locally coming from a regular channel query.
    // This property only lives locally, and it is useful to filter out older pinned messages
    // that do not belong to the regular channel query.
    @NSManaged var oldestMessageAt: DBDate?

    //
    // This field is also used to implement the `clearHistory` option when hiding the channel.
    //
    @NSManaged var truncatedAt: DBDate?

    @NSManaged var isHidden: Bool

    @NSManaged var watcherCount: Int64
    @NSManaged var memberCount: Int64
    
    @NSManaged var isFrozen: Bool
    @NSManaged var cooldownDuration: Int
    @NSManaged var team: String?

    // MARK: - Queries

    // The channel list queries the channel is a part of
    @NSManaged var queries: Set<ChannelListQueryDTO>

    // MARK: - Relationships
    
    @NSManaged var createdBy: UserDTO?
    @NSManaged var members: Set<MemberDTO>

    /// If the current user is a member of the channel, this is their MemberDTO
    @NSManaged var membership: MemberDTO?
    @NSManaged var currentlyTypingUsers: Set<UserDTO>
    @NSManaged var messages: Set<MessageDTO>
    @NSManaged var pinnedMessages: Set<MessageDTO>
    @NSManaged var reads: Set<ChannelReadDTO>
    @NSManaged var watchers: Set<UserDTO>
    @NSManaged var memberListQueries: Set<ChannelMemberListQueryDTO>
    @NSManaged var previewMessage: MessageDTO?
    
    /// If the current channel is muted by the current user, `mute` contains details.
    @NSManaged var mute: ChannelMuteDTO?
    
    override func willSave() {
        super.willSave()

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
        }
        
        // Update the date for sorting every time new message in this channel arrive.
        // This will ensure that the channel list is updated/sorted when new message arrives.
        let lastDate = lastMessageAt ?? createdAt
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
        request.predicate = NSPredicate(format: "cid IN %@", cids)
        return load(by: request, context: context)
    }
    
    static func loadOrCreate(cid: ChannelId, context: NSManagedObjectContext) -> ChannelDTO {
        let request = fetchRequest(for: cid)
        if let existing = load(by: request, context: context).first {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.cid = cid.rawValue
        return new
    }
}

// MARK: - EphemeralValuesContainer

extension ChannelDTO: EphemeralValuesContainer {
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
        query: ChannelListQuery
    ) throws -> [ChannelDTO] {
        // The query will be saved during `saveChannel` call
        // but in case this query does not have any channels,
        // the query won't be saved, which will cause any future
        // channels to not become linked to this query
        _ = saveQuery(query: query)
        
        return try payload.channels.map { channelPayload in
            try saveChannel(payload: channelPayload, query: query)
        }
    }
    
    func saveChannel(
        payload: ChannelDetailPayload,
        query: ChannelListQuery?
    ) throws -> ChannelDTO {
        let dto = ChannelDTO.loadOrCreate(cid: payload.cid, context: self)

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
        dto.config = payload.config.asDTO(context: self, cid: dto.cid)
        dto.createdAt = payload.createdAt.bridgeDate
        dto.deletedAt = payload.deletedAt?.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.defaultSortingAt = (payload.lastMessageAt ?? payload.createdAt).bridgeDate
        dto.lastMessageAt = payload.lastMessageAt?.bridgeDate
        dto.memberCount = Int64(clamping: payload.memberCount)
        dto.truncatedAt = payload.truncatedAt?.bridgeDate
        // We don't always set `truncatedAt` directly since we also use this property as `hiddenAt`
        // when a channel is hidden with `clearHistory`
        // Backend doesn't send `truncatedAt` for this case and we reset it, causing the hidden messages to re-appear
        // It's not possible to set `truncatedAt` to `nil` once it's set on backend side
        // so it's safe to keep client-side changes when backend sends `nil`
        if payload.truncatedAt != nil {
            dto.truncatedAt = payload.truncatedAt?.bridgeDate
        }

        dto.isFrozen = payload.isFrozen
        
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
            let member = try saveMember(payload: memberPayload, channelId: payload.cid)
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
        query: ChannelListQuery?
    ) throws -> ChannelDTO {
        let dto = try saveChannel(payload: payload.channel, query: query)
                
        let reads = Set(
            try payload.channelReads.map {
                try saveChannelRead(payload: $0, for: payload.channel.cid)
            }
        )
        dto.reads.subtracting(reads).forEach { delete($0) }
        dto.reads = reads
        
        try payload.messages.forEach { _ = try saveMessage(payload: $0, channelDTO: dto, syncOwnReactions: true) }
        
        if dto.needsPreviewUpdate(payload) {
            dto.previewMessage = preview(for: payload.channel.cid)
        }

        dto.updateOldestMessageAt(payload: payload)

        try payload.pinnedMessages.forEach {
            _ = try saveMessage(payload: $0, channelDTO: dto, syncOwnReactions: true)
        }
        
        // Sometimes, `members` are not part of `ChannelDetailPayload` so they need to be saved here too.
        try payload.members.forEach {
            let member = try saveMember(payload: $0, channelId: payload.channel.cid)
            dto.members.insert(member)
        }

        if let membership = payload.membership {
            let membership = try saveMember(payload: membership, channelId: payload.channel.cid)
            dto.membership = membership
        } else {
            dto.membership = nil
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

    func cleanChannels(cids: Set<ChannelId>) {
        let channels = ChannelDTO.load(cids: Array(cids), context: self)
        for channelDTO in channels {
            channelDTO.resetEphemeralValues()
            channelDTO.messages.removeAll()
            channelDTO.members.removeAll()
            channelDTO.pinnedMessages.removeAll()
            channelDTO.reads.removeAll()
        }
    }

    func removeChannels(cids: Set<ChannelId>) {
        let channels = ChannelDTO.load(cids: Array(cids), context: self)
        channels.forEach(delete)
    }
}

// To get the data from the DB

extension ChannelDTO {
    static func channelListFetchRequest(
        query: ChannelListQuery
    ) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        
        // Fetch results controller requires at least one sorting descriptor.
        let sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        request.sortDescriptors = sortDescriptors.isEmpty ? [ChannelListSortingKey.defaultSortDescriptor] : sortDescriptors
        
        let matchingQuery = NSPredicate(format: "ANY queries.filterHash == %@", query.filter.filterHash)
        let notDeleted = NSPredicate(format: "deletedAt == nil")

        // If the query contains a filter for the `isHidden` property,
        // we use the filter here
        // This is safe to do since backend appends a `hidden: false` filter when it's not specified
        // (so backend never returns hidden channels unless `hidden: true` is explicitly passed)
        // We can't pass bools directly to NSPredicate so we have to use integers
        let isHidden = NSPredicate(format: "isHidden == %i", query.filter.hiddenFilterValue == true ? 1 : 0)
        
        let subpredicates = [
            matchingQuery, notDeleted, isHidden
        ]
        
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: subpredicates)
        return request
    }
    
    static func channelsFetchRequest(notLinkedTo query: ChannelListQuery) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.sortDescriptors = [ChannelListSortingKey.defaultSortDescriptor]
        // Channels which are not linked to this query
        request.predicate = NSCompoundPredicate(
            notPredicateWithSubpredicate: NSPredicate(
                format: "ANY queries.filterHash == %@", query.filter.filterHash
            )
        )
        return request
    }
}

extension ChannelDTO {
    /// Snapshots the current state of `ChannelDTO` and returns an immutable model object from it.
    func asModel() throws -> ChatChannel { try .create(fromDTO: self) }
}

extension ChatChannel {
    /// Create a ChannelModel struct from its DTO
    fileprivate static func create(fromDTO dto: ChannelDTO) throws -> ChatChannel {
        guard dto.isValid, let cid = try? ChannelId(cid: dto.cid), let context = dto.managedObjectContext else {
            throw InvalidModel(dto)
        }

        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for Channel with cid: <\(dto.cid)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = [:]
        }

        let reads: [ChatChannelRead] = try dto.reads.map { try $0.asModel() }
        
        let unreadCount: () -> ChannelUnreadCount = {
            guard let currentUser = context.currentUser else { return .noUnread }
            
            let currentUserRead = reads.first(where: { $0.user.id == currentUser.user.id })
            
            let allUnreadMessages = currentUserRead?.unreadMessagesCount ?? 0
            
            // Fetch count of all mentioned messages after last read
            // (this is not 100% accurate but it's the best we have)
            let unreadMentionsRequest = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
            unreadMentionsRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                MessageDTO.channelMessagesPredicate(
                    for: dto.cid,
                    deletedMessagesVisibility: context.deletedMessagesVisibility ?? .visibleForCurrentUser,
                    shouldShowShadowedMessages: context.shouldShowShadowedMessages ?? false
                ),
                NSPredicate(format: "createdAt > %@", currentUserRead?.lastReadAt.bridgeDate ?? DBDate(timeIntervalSince1970: 0)),
                NSPredicate(format: "%@ IN mentionedUsers", currentUser.user)
            ])
            
            do {
                return ChannelUnreadCount(
                    messages: allUnreadMessages,
                    mentions: try context.count(for: unreadMentionsRequest)
                )
            } catch {
                log.error("Failed to fetch unread counts for channel `\(cid)`. Error: \(error)")
                return .noUnread
            }
        }
        
        let fetchMessages: () -> [ChatMessage] = {
            MessageDTO
                .load(
                    for: dto.cid,
                    limit: dto.managedObjectContext?.localCachingSettings?.chatChannel.latestMessagesLimit ?? 25,
                    deletedMessagesVisibility: dto.managedObjectContext?.deletedMessagesVisibility ?? .visibleForCurrentUser,
                    shouldShowShadowedMessages: dto.managedObjectContext?.shouldShowShadowedMessages ?? false,
                    context: context
                )
                .compactMap { try? $0.asModel() }
        }
        
        let fetchLatestMessageFromUser: () -> ChatMessage? = {
            guard let currentUser = context.currentUser else { return nil }
            
            return try? MessageDTO
                .loadLastMessage(
                    from: currentUser.user.id,
                    in: dto.cid,
                    context: context
                )?
                .asModel()
        }
        
        let fetchWatchers: () -> [ChatUser] = {
            UserDTO
                .loadLastActiveWatchers(cid: cid, context: context)
                .compactMap { try? $0.asModel() }
        }
        
        let fetchMembers: () -> [ChatChannelMember] = {
            MemberDTO
                .loadLastActiveMembers(cid: cid, context: context)
                .compactMap { try? $0.asModel() }
        }

        let fetchMuteDetails: () -> MuteDetails? = {
            guard let mute = dto.mute else { return nil }
            
            return .init(
                createdAt: mute.createdAt.bridgeDate,
                updatedAt: mute.updatedAt.bridgeDate
            )
        }
        
        return try ChatChannel(
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
            isFrozen: dto.isFrozen,
            lastActiveMembers: { fetchMembers() },
            membership: dto.membership.map { try $0.asModel() },
            currentlyTypingUsers: { Set(dto.currentlyTypingUsers.compactMap { try? $0.asModel() }) },
            lastActiveWatchers: { fetchWatchers() },
            team: dto.team,
            unreadCount: { unreadCount() },
            watcherCount: Int(dto.watcherCount),
            memberCount: Int(dto.memberCount),
            reads: reads,
            cooldownDuration: Int(dto.cooldownDuration),
            extraData: extraData,
            //            invitedMembers: [],
            latestMessages: { fetchMessages() },
            lastMessageFromCurrentUser: { fetchLatestMessageFromUser() },
            pinnedMessages: { dto.pinnedMessages.compactMap { try? $0.asModel() } },
            muteDetails: fetchMuteDetails,
            previewMessage: { try? dto.previewMessage?.asModel() },
            underlyingContext: dto.managedObjectContext
        )
    }
}

// Helpers
private extension ChannelDTO {
    /// Updates the `oldestMessageAt` of the channel. It should only updates if the current `messages: [Message]`
    /// is older than the current `ChannelDTO.oldestMessageAt`, unless the current `ChannelDTO.oldestMessageAt`
    /// is the default one, which is by default a very old date, so are sure the first messages are always fetched.
    func updateOldestMessageAt(payload: ChannelPayload) {
        if let payloadOldestMessageAt = payload.messages.map(\.createdAt).min() {
            let isOlderThanCurrentOldestMessage = payloadOldestMessageAt < (oldestMessageAt?.bridgeDate ?? Date.distantFuture)
            if isOlderThanCurrentOldestMessage {
                oldestMessageAt = payloadOldestMessageAt.bridgeDate
            }
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
