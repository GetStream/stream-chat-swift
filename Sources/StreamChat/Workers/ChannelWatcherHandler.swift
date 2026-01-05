//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles watching channels and prevents duplicate watch requests.
///
/// When a channel is created and belongs to multiple queries at the same time,
/// we want to make sure we only watch it one time, not for every query it belongs.
protocol ChannelWatcherHandling {
    func attemptToWatch(
        channelIds: [ChannelId],
        completion: ((Error?) -> Void)?
    )
}

class ChannelWatcherHandler: ChannelWatcherHandling {
    private let queue = DispatchQueue(label: "io.getstream.ChannelWatcherHandler")
    private let channelListUpdater: ChannelListUpdater
    private var activeWatchRequests: Set<ChannelId> = []

    init(channelListUpdater: ChannelListUpdater) {
        self.channelListUpdater = channelListUpdater
    }

    func attemptToWatch(channelIds: [ChannelId], completion: (((any Error)?) -> Void)?) {
        queue.async {
            // Filter out channels that are already being watched
            let channelsToWatch = channelIds.filter { !self.activeWatchRequests.contains($0) }

            guard !channelsToWatch.isEmpty else {
                completion?(nil)
                return
            }

            self.activeWatchRequests.formUnion(channelsToWatch)

            self.channelListUpdater.startWatchingChannels(
                withIds: channelsToWatch
            ) { [weak self] error in
                self?.queue.async {
                    self?.activeWatchRequests.subtract(channelsToWatch)
                    completion?(error)
                }
            }
        }
    }
}
