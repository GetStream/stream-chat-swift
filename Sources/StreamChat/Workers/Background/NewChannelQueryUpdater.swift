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
        let context = database.backgroundReadOnlyContext
        context.perform { [weak self] in
            let cid = channelDTO.cid
            
            let updatedQueries: [ChannelListQuery] = context
                .loadChannelListQueries()
                .compactMap { dto in
                    guard let query = dto.asModel() else { return nil }
                    
                    return ChannelListQuery(
                        filter: .and([query.filter, .equal("cid", to: cid)]),
                        sort: query.sort,
                        pageSize: 1
                    )
                }
            
            for query in updatedQueries {
                self?.channelListUpdater.fetch(query) {
                    switch $0 {
                    case let .success(payload):
                        guard let channel = payload.channels.first(where: { $0.channel.cid.rawValue == cid }) else {
                            log.debug("Channel \(cid) does not belong to query: \(query)")
                            return
                        }
                        
                        self?.database.write({ session in
                            try session.saveChannel(payload: channel, query: query)
                        }, completion: { error in
                            if let error = error {
                                log.error("Failed to link channel \(channel) to query: \(query): \(error)")
                            }
                        })
                    case let .failure(error):
                        log.error("Internal error. Failed to update query: \(query) for the new channel: \(error)")
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
