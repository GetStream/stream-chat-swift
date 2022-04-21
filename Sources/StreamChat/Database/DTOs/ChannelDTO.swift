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
    
    @NSManaged var createdAt: Date
    @NSManaged var deletedAt: Date?
    @NSManaged var defaultSortingAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var lastMessageAt: Date?

    // The oldest message of the channel we have locally coming from a regular channel query.
    // This property only lives locally, and it is useful to filter out older pinned messages
    // that do not belong to the regular channel query.
    @NSManaged var oldestMessageAt: Date?

    //
    // This field is also used to implement the `clearHistory` option when hiding the channel.
    //
    @NSManaged var truncatedAt: Date?

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

    override func willSave() {
        super.willSave()

        // Change to the `trunctedAt` value have effect on messages, we need to mark them dirty manually
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
        if let dto = context.getCache().get(channelCID: cid.rawValue) {
            return dto
        }

        let request = fetchRequest(for: cid)
        let dto = load(by: request, context: context).first
        if let channel = dto {
            context.getCache().set(channel: channel)
        }

        return dto
    }

    static func load(cids: [ChannelId], context: NSManagedObjectContext) -> [ChannelDTO] {
        guard !cids.isEmpty else { return [] }
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.predicate = NSPredicate(format: "cid IN %@", cids)
        return load(by: request, context: context)
    }
    
    static func loadOrCreate(cid: ChannelId, context: NSManagedObjectContext) -> ChannelDTO {
        if let existing = Self.load(cid: cid, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! ChannelDTO
        new.cid = cid.rawValue
        
        defer {
            context.getCache().set(channel: new)
        }
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

        var encodedData: Data

        do {
            encodedData = try JSONEncoder.default.encode(payload.extraData)
        } catch {
            log.error(
                "Failed to decode extra payload for Channel with cid: <\(dto.cid)>, using default value instead. "
                    + "Error: \(error)"
            )
            encodedData = Data()
        }

        dto.extraData = encodedData
        dto.typeRawValue = payload.typeRawValue
        dto.config = payload.config.asDTO(context: self, cid: dto.cid)
        dto.createdAt = payload.createdAt
        dto.deletedAt = payload.deletedAt
        dto.updatedAt = payload.updatedAt
        dto.defaultSortingAt = payload.lastMessageAt ?? payload.createdAt
        dto.lastMessageAt = payload.lastMessageAt
        dto.memberCount = Int64(clamping: payload.memberCount)
        dto.truncatedAt = payload.truncatedAt

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

        if let members = payload.members {
            try upsertMany(payload: members, channelId: payload.cid).forEach {
                dto.members.insert($0)
            }
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

        _ = try upsertMany(payload: payload.messages, channelDTO: dto)

        dto.updateOldestMessageAt(payload: payload)
        dto.updateLastMessageAt(payload: payload)

        _ = try upsertMany(payload: payload.pinnedMessages, channelDTO: dto)
        
        // Sometimes, `members` are not part of `ChannelDetailPayload` so they need to be saved here too.
        let members = try upsertMany(payload: payload.members, channelId: payload.channel.cid)
        dto.members = Set<MemberDTO>(members)

        _ = try upsertMany(payload: payload.channelReads, for: payload.channel.cid)

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
    func messagesArePopulated() -> Bool {
        if lastMessageAt == nil || oldestMessageAt == nil {
            return true
        }

        let newestMessage = messages.max { a, b in
            a.createdAt < b.createdAt
        }

        return newestMessage?.createdAt == lastMessageAt
    }
}

extension ChannelDTO {
    /// Snapshots the current state of `ChannelDTO` and returns an immutable model object from it.
    func asModel() -> ChatChannel { .create(fromDTO: self) }
}

extension ChatChannel {
    /// Create a ChannelModel struct from its DTO
    fileprivate static func create(fromDTO dto: ChannelDTO) -> ChatChannel {
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

        let cid = try! ChannelId(cid: dto.cid)
        
        let context = dto.managedObjectContext!
        
        let reads: [ChatChannelRead] = dto.reads.map { $0.asModel() }
        
        let unreadCount: () -> ChannelUnreadCount = {
            guard let currentUser = context.currentUser else { return .noUnread }
            
            let currentUserRead = reads.first(where: { $0.user.id == currentUser.user.id })
            
            let allUnreadMessages = currentUserRead?.unreadMessagesCount ?? 0
            
            // Fetch count of all mentioned messages after last read
            // (this is not 100% accurate but it's the best we have)
            let mentionedUnreadMessagesRequest = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
            mentionedUnreadMessagesRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                MessageDTO.channelMessagesPredicate(
                    for: dto.cid,
                    deletedMessagesVisibility: context.deletedMessagesVisibility ?? .visibleForCurrentUser,
                    shouldShowShadowedMessages: context.shouldShowShadowedMessages ?? false
                ),
                NSPredicate(format: "createdAt > %@", currentUserRead?.lastReadAt as NSDate? ?? NSDate(timeIntervalSince1970: 0)),
                NSPredicate(format: "%@ IN mentionedUsers", currentUser.user)
            ])
            
            do {
                return ChannelUnreadCount(
                    messages: allUnreadMessages,
                    mentionedMessages: try context.count(for: mentionedUnreadMessagesRequest)
                )
            } catch {
                log.error("Failed to fetch unread counts for channel `\(cid)`. Error: \(error)")
                return .noUnread
            }
        }
        
        let fetchMessages: () -> [ChatMessage] = {
            let limit = dto.managedObjectContext?.localCachingSettings?.chatChannel.latestMessagesLimit ?? 25
            if dto.messagesArePopulated() {
                return dto.messages.map { $0.asModel() }.sorted { a, b in
                    a.createdAt > b.createdAt
                }
            }
            return MessageDTO
                .load(
                    for: dto.cid,
                    limit: limit,
                    context: context
                )
                .map { $0.asModel() }
        }
        
        // TODO: this makes no sense, we should not store watchers on the database
        let fetchWatchers: () -> [ChatUser] = {
            UserDTO
                .loadLastActiveWatchers(cid: cid, context: context)
                .map { $0.asModel() }
        }
        
        // TODO: really often the DTO is populated with all members, we should skip this query in that case
        let fetchMembers: () -> [ChatChannelMember] = {
            MemberDTO
                .loadLastActiveMembers(cid: cid, context: context)
                .map { $0.asModel() }
        }

        let fetchMuteDetails: () -> MuteDetails? = {
            guard
                let currentUser = context.currentUser,
                let mute = ChannelMuteDTO.load(cid: cid, userId: currentUser.user.id, context: context)
            else { return nil }

            return .init(
                createdAt: mute.createdAt,
                updatedAt: mute.updatedAt
            )
        }
        
        return ChatChannel(
            cid: cid,
            name: dto.name,
            imageURL: dto.imageURL,
            lastMessageAt: dto.lastMessageAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: dto.deletedAt,
            truncatedAt: dto.truncatedAt,
            isHidden: dto.isHidden,
            createdBy: dto.createdBy?.asModel(),
            config: dto.config.asModel(),
            isFrozen: dto.isFrozen,
            lastActiveMembers: { fetchMembers() },
            membership: dto.membership.map { $0.asModel() },
            currentlyTypingUsers: { Set(dto.currentlyTypingUsers.map { $0.asModel() }) },
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
            pinnedMessages: { dto.pinnedMessages.map { $0.asModel() } },
            muteDetails: fetchMuteDetails,
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
            let isOlderThanCurrentOldestMessage = payloadOldestMessageAt < (oldestMessageAt ?? Date.distantFuture)
            if isOlderThanCurrentOldestMessage {
                oldestMessageAt = payloadOldestMessageAt
            }
        }
    }

    func updateLastMessageAt(payload: ChannelPayload) {
        if let payloadLastMessageAt = payload.messages.map(\.createdAt).max() {
            if payloadLastMessageAt > (oldestMessageAt ?? payloadLastMessageAt) {
                lastMessageAt = payloadLastMessageAt
            }
        }
    }
}
