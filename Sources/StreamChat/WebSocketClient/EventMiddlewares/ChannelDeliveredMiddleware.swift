//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware that automatically marks channels as delivered when new messages are received.
/// It throttles the requests to avoid spamming the server and removes channels from tracking
/// when they are marked as read.
class ChannelDeliveredMiddleware: EventMiddleware {
    /// Dictionary to track channels and their latest message IDs for delivery marking.
    var pendingDeliveredChannels: [ChannelId: MessageId] = [:]
    
    /// Throttler to limit the frequency of markChannelsDelivered requests.
    private let throttler: Throttler
    
    /// The current user updater used to mark channels as delivered.
    private let currentUserUpdater: CurrentUserUpdater
    
    /// Queue for thread-safe access to the pending channels dictionary.
    private let queue: DispatchQueue

    /// Creates a new `ChannelDeliveredMiddleware` instance.
    ///
    /// - Parameters:
    ///   - currentUserUpdater: The current user updater used to mark channels as delivered.
    ///   - throttler: The throttler to limit request frequency. Defaults to 1 second interval.
    init(
        currentUserUpdater: CurrentUserUpdater,
        throttler: Throttler = Throttler(interval: 1.0),
        queue: DispatchQueue? = nil,
    ) {
        self.currentUserUpdater = currentUserUpdater
        self.throttler = throttler
        self.queue = queue ?? DispatchQueue(
            label: "io.getstream.channel-delivered-middleware",
            attributes: .concurrent
        )
    }
    
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let messageNewEvent as MessageNewEventDTO:
            handleMessageNewEvent(messageNewEvent)
        case let notificationMarkReadEvent as NotificationMarkReadEventDTO:
            handleNotificationMarkReadEvent(notificationMarkReadEvent)
        default:
            break
        }
        return event
    }
    
    /// Handles a new message event by adding the channel to the pending delivered channels.
    ///
    /// - Parameter event: The message new event.
    private func handleMessageNewEvent(_ event: MessageNewEventDTO) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Update the latest message ID for this channel
            self.pendingDeliveredChannels[event.cid] = event.message.id
            
            // Trigger the throttled mark channels delivered request
            self.throttler.execute { [weak self] in
                self?.markChannelsAsDelivered()
            }
        }
    }
    
    /// Handles a notification mark read event by removing the channel from pending delivered channels.
    ///
    /// - Parameter event: The notification mark read event.
    private func handleNotificationMarkReadEvent(_ event: NotificationMarkReadEventDTO) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.pendingDeliveredChannels.removeValue(forKey: event.cid)
        }
    }
    
    /// Marks all pending channels as delivered and clears the successfully processed channels.
    private func markChannelsAsDelivered() {
        let messages: [DeliveredMessageInfo] = queue.sync {
            return pendingDeliveredChannels.map { channelId, messageId in
                DeliveredMessageInfo(channelId: channelId, messageId: messageId)
            }
        }
        
        guard !messages.isEmpty else { return }
        
        currentUserUpdater.markChannelsDelivered(deliveredMessages: messages) { [weak self] error in
            if let error = error {
                log.error("Failed to mark channels as delivered: \(error)")
                return
            }
            
            // Clear the successfully processed channels
            self?.queue.async(flags: .barrier) { [weak self] in
                let processedChannelIds = Set(messages.map(\.channelId))
                for channelId in processedChannelIds {
                    self?.pendingDeliveredChannels.removeValue(forKey: channelId)
                }
            }
        }
    }
}
