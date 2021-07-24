//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public extension _ChatClient {
    /// Creates a new `ChannelEventsController` that can be used to listen to system events
    /// related to the channel with `cid` and to send custom events.
    ///
    /// - Parameter cid: A channel identifier.
    /// - Returns: A new instance of `ChannelEventsController`.
    func channelEventsController(for cid: ChannelId) -> ChannelEventsController {
        .init(
            cidProvider: { cid },
            eventSender: .init(database: databaseContainer, apiClient: apiClient),
            notificationCenter: eventNotificationCenter
        )
    }
}

public extension _ChatChannelController {
    /// Creates a new `ChannelEventsController` that can be used to listen to system events
    /// and for sending custom events into a channel the current controller manages.
    ///
    /// - Returns: A new instance of `ChannelEventsController`.
    func eventsController() -> ChannelEventsController {
        .init(
            cidProvider: { self.cid },
            eventSender: .init(
                database: client.databaseContainer,
                apiClient: client.apiClient
            ),
            notificationCenter: client.eventNotificationCenter
        )
    }
}

/// `ChannelEventsController` is a controller class which allows to observe channel
/// events and send custom events.
public class ChannelEventsController: EventsController {
    // A channel identifier provider.
    private let cidProvider: () -> ChannelId?
    
    // A channel identifier. Returns `nil` if channel has not yet created.
    public var cid: ChannelId? { cidProvider() }
    
    // An event sender.
    private let eventSender: EventSender
    
    /// Creates a instance of `ChannelEventsController` type.
    /// - Parameters:
    ///   - cid: A channel identifier.
    ///   - eventSender: An event sender.
    ///   - notificationCenter: A notification center.
    init(
        cidProvider: @escaping () -> ChannelId?,
        eventSender: EventSender,
        notificationCenter: EventNotificationCenter
    ) {
        self.cidProvider = cidProvider
        self.eventSender = eventSender
        
        super.init(notificationCenter: notificationCenter)
    }

    /// Sends a custom event to the channel with `cid`.
    ///
    /// - Parameters:
    ///   - payload: A custom event payload to be sent.
    ///   - completion: A completion.
    public func sendEvent<T: CustomEventPayload>(_ payload: T, completion: ((Error?) -> Void)? = nil) {
        guard let cid = cid else {
            callback { completion?(ClientError.ChannelNotCreatedYet()) }
            return
        }
        
        eventSender.sendEvent(payload, to: cid) { error in
            self.callback { completion?(error) }
        }
    }
    
    override func shouldProcessEvent(_ event: Event) -> Bool {
        guard let cid = cid else { return false }
        
        let channelEvent = event as? ChannelSpecificEvent
        let unknownEvent = event as? UnknownEvent
        
        return channelEvent?.cid == cid || unknownEvent?.cid == cid
    }
}
