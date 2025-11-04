//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component that tracks pending channel deliveries and manages throttled requests to mark messages as delivered.
///
/// This component is used in the event middleware and the push notifications handler to
/// avoid spamming the server whenever there is multiple messages coming in.
class ChannelDeliveryTracker {
    /// Dictionary to track channels and their latest message IDs for delivery marking.
    private(set) var pendingDeliveredChannels: [ChannelId: MessageId] = [:]

    /// Throttler to limit the frequency of the requests.
    private let throttler: Throttler
    
    /// The current user updater used to mark messages as delivered.
    private let currentUserUpdater: CurrentUserUpdater
    
    /// Queue for thread-safe access to the pending channels dictionary.
    private let queue: DispatchQueue
    
    /// Creates a new `ChannelDeliveryTracker` instance.
    ///
    /// - Parameters:
    ///   - currentUserUpdater: The current user updater used to mark messages as delivered.
    ///   - throttler: The throttler to limit request frequency. Defaults to 1 second interval.
    ///   - queue: Optional custom queue for thread-safe operations. Defaults to a concurrent queue.
    init(
        currentUserUpdater: CurrentUserUpdater,
        throttler: Throttler = Throttler(interval: 1.0),
        queue: DispatchQueue? = nil
    ) {
        self.currentUserUpdater = currentUserUpdater
        self.throttler = throttler
        self.queue = queue ?? DispatchQueue(
            label: "io.getstream.channel-delivery-tracker",
            attributes: .concurrent
        )
    }
    
    /// Adds a channel and message to the pending delivered channels.
    ///
    /// Executes the request if no request is being throttled.
    ///
    /// - Parameters:
    ///   - channelId: The channel identifier.
    ///   - messageId: The message identifier.
    func submitForDelivery(channelId: ChannelId, messageId: MessageId) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Update the latest message ID for this channel
            self.pendingDeliveredChannels[channelId] = messageId
            
            // Trigger mark channels delivered request
            self.markMessagesAsDelivered()
        }
    }
    
    /// Cancels a channel from being marked as delivered.
    ///
    /// - Parameter channelId: The channel identifier to remove.
    func cancel(channelId: ChannelId) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.pendingDeliveredChannels.removeValue(forKey: channelId)
        }
    }
    
    /// Marks all pending messages as delivered and clears the successfully processed messages.
    private func markMessagesAsDelivered() {
        throttler.execute { [weak self] in
            let deliveredMessages: [MessageDeliveryInfo] = self?.queue.sync {
                return self?.pendingDeliveredChannels.map { channelId, messageId in
                    MessageDeliveryInfo(channelId: channelId, messageId: messageId)
                }
            } ?? []

            guard !deliveredMessages.isEmpty else { return }

            self?.currentUserUpdater.markMessagesAsDelivered(deliveredMessages) { [weak self] error in
                if let error = error {
                    log.error("Failed to mark channels as delivered: \(error)")
                    return
                }

                // Clear the successfully processed channels in case
                // there are no new message ids.
                self?.queue.async(flags: .barrier) { [weak self] in
                    for deliveredMessage in deliveredMessages {
                        let messageId = deliveredMessage.messageId
                        let channelId = deliveredMessage.channelId
                        let currentMessageId = self?.pendingDeliveredChannels[channelId]
                        if currentMessageId == messageId {
                            self?.pendingDeliveredChannels[channelId] = nil
                        }
                    }
                }
            }
        }
    }
}
