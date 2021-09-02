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
        fetchRequest: ChannelDTO.channelWithoutQueryFetchRequest,
        itemCreator: { $0.asModel() }
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
                self?.channelsObserver.items.forEach {
                    self?.linkChannelToExistedQueries($0.cid)
                }
            } catch {
                log.error("Error starting NewChannelQueryUpdater observer: \(error)")
            }
        }
    }
    
    private func handle(changes: [ListChange<ChatChannel>]) {
        // Observe `ChannelDTO` insertions
        changes.forEach { change in
            switch change {
            case let .insert(channel, _):
                let cid = channel.cid
                database.write {
                    let dto = $0.channel(cid: cid)
                    dto?.needsRefreshQueries = false
                } completion: { _ in
                    self.linkChannelToExistedQueries(cid)
                }

            default: return
            }
        }
    }
    
    private func linkChannelToExistedQueries(_ cid: ChannelId) {
        fetchExistedQueries { [weak self] queries in
            for query in queries {
                self?.linkChannelToQueryIfNeeded(cid, query: query)
            }
        }
    }
    
    private func linkChannelToQueryIfNeeded(_ cid: ChannelId, query: ChannelListQuery) {
        var queryWithNewChannel = ChannelListQuery(
            filter: .and([query.filter, .equal(.cid, to: cid)]),
            pageSize: 1
        )
        queryWithNewChannel.options = []
        
        channelListUpdater.fetch(queryWithNewChannel) { [weak self] in
            switch $0 {
            case let .success(payload):
                guard let channel = payload.channels.first(where: { $0.channel.cid == cid }) else {
                    return
                }
                
                self?.save(channel, andLinkTo: query)
            case let .failure(error):
                log.error("Failed to check if query should include new channel: \(error)")
            }
        }
    }
    
    private func fetchExistedQueries(_ completion: @escaping ([ChannelListQuery]) -> Void) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            let queries = context
                .loadChannelListQueries()
                .compactMap { $0.asModel() }
            
            completion(queries)
        }
    }
    
    private func save(_ channel: ChannelPayload, andLinkTo query: ChannelListQuery) {
        database.write({ session in
            _ = try session.saveChannel(payload: channel, query: query)
        }, completion: { error in
            if let error = error {
                log.error("Failed to link new channel: \(channel.channel.cid) to query \(error)")
            }
        })
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
