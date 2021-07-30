//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

/// After creating new channel it's not observed cause it's not linked to any ChannelListQuery.
/// The only job of `NewChannelQueryUpdater` is to find whether new channel belongs to any of the existing queries
/// and link it to the channel if so.
///     1. This worker observers DB for the insertions of the new `ChannelDTO`s without any linked queries.
///     2. When new channel is found, all existing queries are fetched from DB and we modify existing queries filters so
///     in response for `update(channelListQuery` request new channel will be returned if it is part of the original query filter.
///     3. After sending `update(channelListQuery` for all queries `ChannelListUpdater` does the job of linking
///     corresponding queries to the channel.
final class NewChannelQueryUpdater: Worker {
    private let environment: Environment
        
    private lazy var channelListUpdater: ChannelListUpdater = self.environment
        .createChannelListUpdater(
            database,
            apiClient
        )
    
    private lazy var channelsObserver: ListDatabaseObserver = .init(
        context: self.database.backgroundReadOnlyContext,
        fetchRequest: ChannelDTO.channelWithoutQueryFetchRequest
    )
    
    private var queries: [ChannelListQueryDTO] {
        do {
            let queries = try database.backgroundReadOnlyContext
                .fetch(NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName))
            return queries
        } catch {
            log.error("Internal error: Failed to fetch [ChannelListQueryDTO]: \(error)")
        }
        return []
    }
    
    init(database: DatabaseContainer, apiClient: APIClient, env: Environment) {
        environment = env
        super.init(database: database, apiClient: apiClient)
        
        startObserving()
    }
    
    override convenience init(database: DatabaseContainer, apiClient: APIClient) {
        self.init(database: database, apiClient: apiClient, env: .init())
    }
    
    private func startObserving() {
        // We have to initialize the lazy variables synchronously
        _ = channelListUpdater
        _ = channelsObserver
        
        // But the observing can be started on a background queue
        DispatchQueue.global().async { [weak self] in
            do {
                self?.channelsObserver.onChange = { changes in
                    self?.handle(changes: changes)
                }
                try self?.channelsObserver.startObserving()
                self?.channelsObserver.items.forEach { self?.updateChannelListQuery(for: $0) }
            } catch {
                log.error("Error starting NewChannelQueryUpdater observer: \(error)")
            }
        }
    }
    
    private func handle(changes: [ListChange<ChannelDTO>]) {
        // Observe `ChannelDTO` insertions
        changes.forEach { change in
            switch change {
            case let .insert(channelDTO, _):
                let cid = channelDTO.cid
                
                database.write {
                    let dto = $0.channel(cid: try! ChannelId(cid: cid))
                    dto?.needsRefreshQueries = false
                } completion: { _ in
                    self.updateChannelListQuery(for: channelDTO)
                }

            default: return
            }
        }
    }
    
    private func updateChannelListQuery(for channelDTO: ChannelDTO) {
        database.backgroundReadOnlyContext.perform { [weak self] in
            guard let queries = self?.queries else { return }
            
            var updatedQueries: [ChannelListQuery] = []
            
            do {
                updatedQueries = try queries.map {
                    // Modify original query filter
                    try $0.asChannelListQueryWithUpdatedFilter(filterToAdd: .equal("cid", to: channelDTO.cid))
                }
                
            } catch {
                log.error("Internal error. Failed to update ChannelListQueries for the new channel: \(error)")
            }
            
            // Send `update(channelListQuery:` requests so corresponding queries will be linked to the channel
            updatedQueries.forEach {
                self?.channelListUpdater.update(channelListQuery: $0) { error in
                    if let error = error {
                        log
                            .error("Internal error. Failed to update ChannelListQueries for the new channel: \(error)")
                    }
                }
            }
        }
    }
}

extension NewChannelQueryUpdater {
    struct Environment {
        var createChannelListUpdater: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = ChannelListUpdater.init
    }
}

private extension ChannelListQueryDTO {
    func asChannelListQueryWithUpdatedFilter(
        filterToAdd filter: Filter<ChannelListFilterScope>
    ) throws -> ChannelListQuery {
        let encodedFilter = try JSONDecoder.default
            .decode(Filter<ChannelListFilterScope>.self, from: filterJSONData)
        
        // We need to pass original `filterHash` so channel will be linked to original query, not the modified one
        var updatedFilter: Filter<ChannelListFilterScope> = .and([encodedFilter, filter])
        updatedFilter.explicitHash = filterHash
        
        return ChannelListQuery(filter: updatedFilter)
    }
}
