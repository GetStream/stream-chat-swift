//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Keeps track of ongoing channel watching requests to prevent duplicate calls.
class WatchingChannelsActiveRequests {
    private var ongoingWatchRequests: Set<ChannelId> = []
    private let queue = DispatchQueue(
        label: "io.getstream.WatchingChannelsOngoingRequests",
        attributes: .concurrent
    )

    /// Checks if a channel is currently executing a watch request.
    /// - Parameter channelId: The channel ID to check.
    /// - Returns: `true` if the channel has an ongoing request, `false` otherwise.
    func isExecutingRequest(for channelId: ChannelId) -> Bool {
        queue.sync {
            ongoingWatchRequests.contains(channelId)
        }
    }

    /// Checks if any of the channel IDs are currently executing a watch request.
    /// - Parameter channelIds: The channel IDs to check.
    /// - Returns: `true` if any of the channels have an ongoing request, `false` otherwise.
    func isExecutingRequests(for channelIds: [ChannelId]) -> Bool {
        queue.sync {
            channelIds.contains { ongoingWatchRequests.contains($0) }
        }
    }

    /// Adds channel IDs to the ongoing requests.
    /// - Parameter channelIds: The channel IDs to check.
    func add(channelIds: [ChannelId]) {
        queue.async(flags: .barrier) { [weak self] in
            self?.ongoingWatchRequests.formUnion(channelIds)
        }
    }

    /// Removes channel IDs from the ongoing requests.
    /// - Parameter channelIds: The channel IDs to remove.
    func remove(channelIds: [ChannelId]) {
        queue.async(flags: .barrier) { [weak self] in
            self?.ongoingWatchRequests.subtract(channelIds)
        }
    }
}
