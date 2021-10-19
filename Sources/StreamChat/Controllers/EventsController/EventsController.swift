//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers = BasePublishers(controller: self)
    
    /// A backing object used to deliver updates to main and additional delegates.
    var multicastDelegate = MulticastDelegate<EventsControllerDelegate>()
    
    /// A delegate the controller notifies about the updates.
    public var delegate: EventsControllerDelegate? {
        get { multicastDelegate.delegates.first }
        set { newValue.map { multicastDelegate.add($0) } }
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

/// An wrapper around `EventsControllerDelegate` which holds a weak reference
/// to the underlaying delegate.
class AnyEventsControllerDelegate: EventsControllerDelegate {
    weak var delegate: EventsControllerDelegate?
   
    init(delegate: EventsControllerDelegate) {
        self.delegate = delegate
    }
    
    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        delegate?.eventsController(controller, didReceiveEvent: event)
    }
}
