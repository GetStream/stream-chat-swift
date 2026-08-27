//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

extension ChannelSearchState {
    final class Observer {
        private let clientConfig: ChatClientConfig
        private let database: DatabaseContainer
        private var channelsObserver: StateLayerDatabaseObserver<ListResult, ChatChannel, ChannelDTO>?
        private var handlers: Handlers?

        init(database: DatabaseContainer, clientConfig: ChatClientConfig) {
            self.database = database
            self.clientConfig = clientConfig
        }

        struct Handlers {
            let channelsDidChange: @Sendable @MainActor ([ChatChannel]) async -> Void
        }

        func start(with handlers: Handlers) {
            self.handlers = handlers
        }

        var query: ChannelListQuery? {
            didSet {
                reset(to: query)
            }
        }

        private func reset(to query: ChannelListQuery?) {
            guard let handlers else { return }
            guard let query else {
                channelsObserver = nil
                return
            }
            let observer = StateLayerDatabaseObserver<ListResult, ChatChannel, ChannelDTO>(
                database: database,
                fetchRequest: ChannelDTO.channelListFetchRequest(
                    query: query,
                    chatClientConfig: clientConfig
                ),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatChannel.cid.rawValue, \ChannelDTO.cid),
                runtimeSorting: query.runtimeSortingValues
            )
            channelsObserver = observer
            do {
                let channels = try observer.startObserving(didChange: handlers.channelsDidChange)
                Task.mainActor { await handlers.channelsDidChange(channels) }
            } catch {
                log.error("Failed to start the channel search result observer for query \(query) with error \(error)")
            }
        }
    }
}
