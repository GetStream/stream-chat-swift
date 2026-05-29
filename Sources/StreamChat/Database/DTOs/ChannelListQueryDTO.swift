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

    // MARK: - Relationships

    @NSManaged var channels: Set<ChannelDTO>

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
    func channelListQuery(query: ChannelListQuery) -> ChannelListQueryDTO? {
        ChannelListQueryDTO.load(query: query, context: self)
    }

    /// Returns the query with persisted predefined filter/sort applied.
    /// `nil` when the input has no `predefinedFilter` or no cached DTO exists.
    /// Callers compare `filter`/`sort` against the input (see `ChannelListQuery.isFilterEqual(to:)`)
    /// to detect whether the cached resolution actually differs from the current query.
    func loadPredefinedFilter(for query: ChannelListQuery) -> ChannelListQuery? {
        guard let predefinedFilter = query.predefinedFilter, !predefinedFilter.isEmpty,
              let dto = channelListQuery(query: query) else {
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
                updated.sort = try [Sorting<ChannelListSortingKey>].predefinedFilterSort(fromJSONData: sortJSONData)
            } catch {
                log.error("Failed decoding predefined sort from persisted data with error: \(error).")
            }
        }
        return updated
    }

    func saveQuery(query: ChannelListQuery, predefinedFilter: PredefinedFilterPayload? = nil) -> ChannelListQueryDTO {
        let dto: ChannelListQueryDTO
        if let existingDTO = channelListQuery(query: query) {
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
                dto.sortJSONData = try JSONEncoder.default.encode(predefinedFilter.sort)
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
}
