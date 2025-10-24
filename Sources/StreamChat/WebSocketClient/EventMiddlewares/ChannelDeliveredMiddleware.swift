//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware that automatically marks channels as delivered when new messages are received.
class ChannelDeliveredMiddleware: EventMiddleware {
    /// The delivery tracker that manages pending deliveries and throttling.
    private let deliveryTracker: ChannelDeliveryTracker

    /// Creates a new `ChannelDeliveredMiddleware` instance.
    ///
    /// - Parameter deliveryTracker: The delivery tracker instance.
    init(deliveryTracker: ChannelDeliveryTracker) {
        self.deliveryTracker = deliveryTracker
    }
    
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let messageNewEvent as MessageNewEventDTO:
            if session.currentUser?.user.id == messageNewEvent.message.user.id {
                break
            }
            handleMessageNewEvent(messageNewEvent)
        case let notificationMarkReadEvent as NotificationMarkReadEventDTO:
            handleNotificationMarkReadEvent(notificationMarkReadEvent)
        case let messageDeliveredEvent as MessageDeliveredEventDTO:
            handleMessageDeliveredEvent(messageDeliveredEvent, session: session)
        default:
            break
        }
        return event
    }
    
    /// Handles a new message event by adding the channel to the pending delivered channels.
    ///
    /// - Parameter event: The message new event.
    private func handleMessageNewEvent(_ event: MessageNewEventDTO) {
        deliveryTracker.submitForDelivery(channelId: event.cid, messageId: event.message.id)
    }
    
    /// Handles a notification mark read event by removing the channel from pending delivered channels.
    ///
    /// - Parameter event: The notification mark read event.
    private func handleNotificationMarkReadEvent(_ event: NotificationMarkReadEventDTO) {
        deliveryTracker.cancel(channelId: event.cid)
    }
    
    /// Handles a message delivered event by updating the local channel read data.
    ///
    /// - Parameters:
    ///   - event: The message delivered event.
    ///   - session: The database session.
    private func handleMessageDeliveredEvent(_ event: MessageDeliveredEventDTO, session: DatabaseSession) {
        // Update the delivered message information
        if let channelRead = session.loadOrCreateChannelRead(
            cid: event.cid,
            userId: event.user.id
        ) {
            channelRead.lastDeliveredAt = event.lastDeliveredAt.bridgeDate
            channelRead.lastDeliveredMessageId = event.lastDeliveredMessageId
        }

        // Remove pending for delivery if marked delivered from another device
        if let message = session.message(id: event.lastDeliveredMessageId),
           message.user.id == session.currentUser?.user.id {
            deliveryTracker.cancel(channelId: event.cid)
        }
    }
}
