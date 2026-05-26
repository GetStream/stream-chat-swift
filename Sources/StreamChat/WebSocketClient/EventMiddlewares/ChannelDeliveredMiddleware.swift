//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware that automatically marks channels as delivered when new messages are received.
class ChannelDeliveredMiddleware: EventMiddleware {
    /// The delivery tracker that manages pending deliveries and throttling.
    private let deliveryTracker: ChannelDeliveryTracker
    
    /// The validator used to determine if messages can be marked as delivered.
    private let deliveryCriteriaValidator: MessageDeliveryCriteriaValidating

    /// Creates a new `ChannelDeliveredMiddleware` instance.
    ///
    /// - Parameters:
    ///   - deliveryTracker: The delivery tracker instance.
    ///   - deliveryCriteriaValidator: The validator for delivery criteria. Defaults to `MessageDeliveryCriteriaValidator()`.
    init(
        deliveryTracker: ChannelDeliveryTracker,
        deliveryCriteriaValidator: MessageDeliveryCriteriaValidating = MessageDeliveryCriteriaValidator()
    ) {
        self.deliveryTracker = deliveryTracker
        self.deliveryCriteriaValidator = deliveryCriteriaValidator
    }
    
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let messageNewEvent as MessageNewEventDTO:
            handleMessageNewEvent(messageNewEvent, session: session)
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
    /// - Parameters:
    ///   - event: The message new event.
    ///   - session: The database session.
    private func handleMessageNewEvent(_ event: MessageNewEventDTO, session: DatabaseSession) {
        guard let domainEvent = event.toDomainEvent(session: session) as? MessageNewEvent else {
            return
        }

        guard let currentUser = (try? session.currentUser?.asModel()) else {
            return
        }

        let channel = domainEvent.channel
        let message = domainEvent.message

        guard deliveryCriteriaValidator.canMarkMessageAsDelivered(message, for: currentUser, in: channel) else {
            return
        }

        if let cidString = event.cid, let cid = try? ChannelId(cid: cidString) {
            deliveryTracker.submitForDelivery(channelId: cid, messageId: event.message.id)
        }
    }
    
    /// Handles a notification mark read event by removing the channel from pending delivered channels.
    ///
    /// - Parameter event: The notification mark read event.
    private func handleNotificationMarkReadEvent(_ event: NotificationMarkReadEventDTO) {
        guard let cidString = event.cid, let cid = try? ChannelId(cid: cidString) else { return }
        deliveryTracker.cancel(channelId: cid)
    }
    
    /// Handles a message delivered event by updating the local channel read data.
    ///
    /// - Parameters:
    ///   - event: The message delivered event.
    ///   - session: The database session.
    private func handleMessageDeliveredEvent(_ event: MessageDeliveredEventDTO, session: DatabaseSession) {
        guard let cidString = event.cid, let cid = try? ChannelId(cid: cidString) else { return }
        guard let userId = event.user?.id else { return }
        guard let lastDeliveredAtString = event.lastDeliveredAt,
              let lastDeliveredAtDate = parseISO8601(lastDeliveredAtString) else { return }
        guard let lastDeliveredMessageId = event.lastDeliveredMessageId else { return }

        // Update the delivered message information
        if let channelRead = session.loadOrCreateChannelRead(cid: cid, userId: userId) {
            channelRead.lastDeliveredAt = lastDeliveredAtDate.bridgeDate
            channelRead.lastDeliveredMessageId = lastDeliveredMessageId
        }

        // Remove pending for delivery if marked delivered from another device
        if let message = session.message(id: lastDeliveredMessageId),
           message.user.id == session.currentUser?.user.id {
            deliveryTracker.cancel(channelId: cid)
        }
    }

    private func parseISO8601(_ string: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: string) { return date }
        return ISO8601DateFormatter().date(from: string)
    }
}
