//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles watching channels and prevents duplicate watch requests.
///
/// When a channel is created and belongs to multiple queries at the same time,
/// we want to make sure we only watch it one time, not for every query it belongs.
protocol ChannelWatcherHandling: Sendable {
    func attemptToWatch(
        channelIds: [ChannelId],
        completion: (@Sendable (Error?) -> Void)?
    )
}

class ChannelWatcherHandler: ChannelWatcherHandling, @unchecked Sendable {
    private let queue = DispatchQueue(label: "io.getstream.ChannelWatcherHandler")
    private let channelListUpdater: ChannelListUpdater
    private var activeWatchRequests: Set<ChannelId> = []

    init(channelListUpdater: ChannelListUpdater) {
        self.channelListUpdater = channelListUpdater
    }

    func attemptToWatch(channelIds: [ChannelId], completion: (@Sendable ((any Error)?) -> Void)?) {
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
                self?.queue.async { [weak self] in
                    self?.activeWatchRequests.subtract(channelsToWatch)
                    completion?(error)
                }
            }
        }
    }
}
