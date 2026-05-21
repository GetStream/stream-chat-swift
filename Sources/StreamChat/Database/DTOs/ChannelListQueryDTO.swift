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

    /// Next-page cursor returned by the grouped channels endpoint for this group.
    /// `nil` means there is no next page (either never paginated or the backend
    /// signaled exhaustion). Only meaningful for queries that carry a `groupKey`.
    @NSManaged var next: String?

    /// The `watch` flag that the original grouped-channels request was issued with.
    ///
    /// Persisted so that subsequent paginated fetches (via `ChannelList`) and the
    /// `SyncRepository` refetch after reconnect can reuse the same value the caller
    /// passed to `ChatClient.queryGroupedChannels(limit:presence:watch:)` instead of
    /// silently downgrading to `false`.
    ///
    /// When `watch` is `false`, ordinary channel and member WebSocket events
    /// (`message.new`, `channel.updated`, etc.) still arrive for channels the current
    /// user is a member of. What `watch == true` additionally enables is the
    /// watcher-scoped event stream — most notably typing indicators
    /// (`typing.start` / `typing.stop`) — so any UI that needs typing indicators
    /// on a grouped channel must pass `watch: true` on the initial query.
    ///
    /// Only meaningful for queries that carry a `groupKey`; filter-based queries
    /// derive watching from `ChannelListQuery.options`.
    @NSManaged var watch: Bool

    /// The `presence` flag that the original grouped-channels request was issued with.
    ///
    /// Persisted so that subsequent paginated fetches and sync refetches reuse the
    /// same value, keeping presence info in responses and presence updates on the
    /// WebSocket consistent across the lifetime of the group subscription.
    ///
    /// Only meaningful for queries that carry a `groupKey`.
    @NSManaged var presence: Bool

    // MARK: - Relationships

    @NSManaged var channels: Set<ChannelDTO>

    static func load(filterHash: String, context: NSManagedObjectContext) -> ChannelListQueryDTO? {
        load(
            keyPath: #keyPath(ChannelListQueryDTO.filterHash),
            equalTo: filterHash,
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
        ChannelListQueryDTO.load(filterHash: query.queryHash, context: self)
    }

    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO {
        if let existingDTO = channelListQuery(query) {
            return existingDTO
        }

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

        return newDTO
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
}
