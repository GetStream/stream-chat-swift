//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ChatClient {
    /// Creates a new `EventsController` that can be used for event listening.
    ///
    /// - Returns: A new instance of `EventsController`.
    func eventsController() -> EventsController {
        .init(notificationCenter: eventNotificationCenter)
    }
}

/// `EventsController` uses this protocol to communicate events to the delegate.
public protocol EventsControllerDelegate: AnyObject {
    /// The method is invoked when an event is observed.
    /// - Parameters:
    ///   - controller: The events controller listening for the events.
    ///   - event: The observed event.
    func eventsController(_ controller: EventsController, didReceiveEvent event: Event)
}

/// `EventsController` is a controller class which allows to observe custom and system events.
public class EventsController: Controller, DelegateCallable {
    // An underlaying observer listening for events.
    private var observer: EventObserver!

    /// A callback queue on which delegate methods are invoked.
    public var callbackQueue: DispatchQueue = .main

    var _basePublishers: Any?
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    /// A backing object used to deliver updates to main and additional delegates.
    var multicastDelegate = MulticastDelegate<EventsControllerDelegate>()

    /// A delegate the controller notifies about the updates.
    public var delegate: EventsControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// Create a new instance of `EventsController`.
    ///
    /// - Parameter notificationCenter: A notification center that is listened for events.
    init(notificationCenter: EventNotificationCenter) {
        observer = .init(
            notificationCenter: notificationCenter,
            transform: { $0 },
            callback: { [weak self] event in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                guard self.shouldProcessEvent(event) else { return }

                self.delegateCallback { [weak self] in
                    guard let self = self else {
                        log.warning("Callback called while self is nil")
                        return
                    }

                    $0.eventsController(self, didReceiveEvent: event)
                }
            }
        )
    }

    /// A function that acts as a filter for incoming events.
    ///
    /// - Parameter event: An event to make a decision about.
    /// - Returns: A result saying if the event should be processed.
    func shouldProcessEvent(_ event: Event) -> Bool {
        true
    }
}
