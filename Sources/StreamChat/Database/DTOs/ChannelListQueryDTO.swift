//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(ChannelListQueryDTO)
class ChannelListQueryDTO: NSManagedObject {
    /// Unique identifier of the query/
    @NSManaged var filterHash: String

    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated, i.e. for newly created channels.
    @NSManaged var filterJSONData: Data

    /// Serialized sort JSON returned by the server for predefined-filter queries.
    @NSManaged var sortJSONData: Data?

    /// Next-page cursor for grouped queries; `nil` when there are no more pages.
    @NSManaged var next: String?

    /// `watch` flag from the original grouped-channels request, reused on pagination
    /// and sync refetches. Grouped queries only.
    @NSManaged var watch: Bool

    /// `presence` flag from the original grouped-channels request, reused on pagination
    /// and sync refetches. Grouped queries only.
    @NSManaged var presence: Bool

    @NSManaged var groupFilterJSONData: Data?
    @NSManaged var groupSortJSONData: Data?
    @NSManaged var groupNotLoadedUnreadCount: Int64

    // MARK: - Relationships

    @NSManaged var channels: Set<ChannelDTO>

    func loadedUnreadChannelsCount(currentUserId: UserId) -> Int {
        channels.filter { Self.unreadMessageCount(of: $0, currentUserId: currentUserId) > 0 }.count
    }

    func updateGroupNotLoadedUnreadCount(unreadChannels: Int, currentUserId: UserId) {
        guard groupFilterJSONData != nil else { return }
        groupNotLoadedUnreadCount = Int64(max(0, unreadChannels - loadedUnreadChannelsCount(currentUserId: currentUserId)))
    }

    static func unreadMessageCount(of channel: ChannelDTO, currentUserId: UserId) -> Int {
        // Reads `reads` because `ChannelDTO.currentUserUnreadMessagesCount` is only updated on save.
        guard !channel.isHidden, !channel.isDisabled, channel.deletedAt == nil else { return 0 }
        return Int(channel.reads.first(where: { $0.user.id == currentUserId })?.unreadMessageCount ?? 0)
    }

    static func load(query: ChannelListQuery, context: NSManagedObjectContext) -> ChannelListQueryDTO? {
        load(
            keyPath: #keyPath(ChannelListQueryDTO.filterHash),
            equalTo: query.queryHash,
            context: context
        ).first as? Self
    }

    /// The fetch request that returns all existed queries from the database.
    static var allQueriesFetchRequest: NSFetchRequest<ChannelListQueryDTO> {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ChannelListQueryDTO.filterHash, ascending: false)
        ]
        return request
    }
}

extension NSManagedObjectContext {
    func channelListQuery(_ query: ChannelListQuery) -> ChannelListQueryDTO? {
        ChannelListQueryDTO.load(query: query, context: self)
    }

    /// Returns the query with persisted predefined filter/sort applied.
    /// `nil` when the input has no `predefinedFilter` or no cached DTO exists.
    /// Callers compare `filter`/`sort` against the input (see `ChannelListQuery.isFilterEqual(to:)`)
    /// to detect whether the cached resolution actually differs from the current query.
    func loadPredefinedFilter(for query: ChannelListQuery) -> ChannelListQuery? {
        if query.groupKey != nil {
            return loadGroupedSort(for: query)
        }
        guard let predefinedFilter = query.predefinedFilter, !predefinedFilter.isEmpty,
              let dto = channelListQuery(query) else {
            return nil
        }

        var updated = query
        do {
            if let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: dto.filterJSONData) {
                updated.filter = filter
            }
        } catch {
            log.error("Failed decoding predefined filter from persisted data with error: \(error).")
        }
        if let sortJSONData = dto.sortJSONData {
            do {
                if let sort = try [Sorting<ChannelListSortingKey>].predefinedFilterSort(fromJSONData: sortJSONData) {
                    updated.sort = sort
                }
            } catch {
                log.error("Failed decoding predefined sort from persisted data with error: \(error).")
            }
        }
        return updated
    }

    private func loadGroupedSort(for query: ChannelListQuery) -> ChannelListQuery? {
        guard let dto = channelListQuery(query) else { return nil }
        var updated = query
        updated.sort = (try? dto.groupSortJSONData.flatMap { try [Sorting<ChannelListSortingKey>].predefinedFilterSort(fromJSONData: $0) }) ?? []
        return updated
    }

    func saveQuery(query: ChannelListQuery, predefinedFilter: PredefinedFilterPayload? = nil) -> ChannelListQueryDTO {
        let dto: ChannelListQueryDTO
        if let existingDTO = channelListQuery(query) {
            dto = existingDTO
        } else {
            let request = ChannelListQueryDTO.fetchRequest(
                keyPath: #keyPath(ChannelListQueryDTO.filterHash),
                equalTo: query.queryHash
            )
            let newDTO = NSEntityDescription.insertNewObject(into: self, for: request)
            newDTO.filterHash = query.queryHash

            let jsonData: Data
            do {
                jsonData = try JSONEncoder.default.encode(query.filter)
            } catch {
                log.error("Failed encoding query Filter data with error: \(error).")
                jsonData = Data()
            }
            newDTO.filterJSONData = jsonData
            dto = newDTO
        }

        if let predefinedFilter {
            do {
                dto.filterJSONData = try JSONEncoder.default.encode(predefinedFilter.filter)
            } catch {
                log.error("Failed encoding predefined filter from response with error: \(error).")
            }
            do {
                dto.sortJSONData = try predefinedFilter.sort.map { try JSONEncoder.default.encode($0) }
            } catch {
                log.error("Failed encoding predefined sort from response with error: \(error).")
            }
        }

        return dto
    }

    func loadAllChannelListQueries() -> [ChannelListQueryDTO] {
        let queries: [ChannelListQueryDTO]

        do {
            queries = try fetch(ChannelListQueryDTO.allQueriesFetchRequest)
        } catch {
            log.error("Failed to load channel list queries from the database: \(error).")
            queries = []
        }

        return queries
    }

    func loadFilteredGroupChannelListQueries() -> [ChannelListQueryDTO] {
        let request = ChannelListQueryDTO.allQueriesFetchRequest
        request.predicate = NSPredicate(format: "%K != nil", #keyPath(ChannelListQueryDTO.groupFilterJSONData))
        do {
            return try fetch(request)
        } catch {
            log.error("Failed to load filtered group channel list queries from the database: \(error).")
            return []
        }
    }

    func unlinkGroupedChannels(in groupKey: String) throws {
        guard let queryDTO = channelListQuery(ChannelListQuery(groupKey: groupKey)) else { return }
        let filterClosure = try groupedChannelsFilter(for: queryDTO)
        let unlinked = queryDTO.channels.filter { !filterClosure($0, groupKey) }
        guard !unlinked.isEmpty else { return }
        queryDTO.channels.subtract(unlinked)
        updateFilteredGroupUnreadChannelCounts(for: [queryDTO])
    }

    func canLinkChannel(_ channel: ChannelDTO, toGroup groupKey: String) throws -> Bool {
        guard let queryDTO = channelListQuery(ChannelListQuery(groupKey: groupKey)) else { return false }
        let filterClosure = try groupedChannelsFilter(for: queryDTO)
        return filterClosure(channel, groupKey)
    }
    
    private func groupedChannelsFilter(for queryDTO: ChannelListQueryDTO) throws -> (ChannelDTO, String) -> Bool {
        let groupFilterPredicate: NSPredicate? = try {
            guard let filterData = queryDTO.groupFilterJSONData else { return nil }
            let filter = try Filter<GroupedChannelsFilterScope>.groupedFilter(fromJSONData: filterData)
            return filter?.predicate
        }()
        let currentUserId = currentUser?.user.id
        return { channel, groupKey in
            let canShowChannel = !channel.isHidden && !channel.isDisabled && channel.deletedAt == nil
            // Channels saved from notification events carry `members` but no `membership`.
            let isMember = channel.membership != nil || channel.members.contains { $0.user.id == currentUserId }
            let isMemberInGroup = isMember && (groupKey == GroupedChannelKey.all || channel.group == groupKey)
            return canShowChannel && isMemberInGroup && (groupFilterPredicate?.evaluate(with: channel) ?? true)
        }
    }
}
