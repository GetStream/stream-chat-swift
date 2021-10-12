//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension EventsController {
    /// A publisher emitting a new value every time an event is observed.
    public var allEventsPublisher: AnyPublisher<Event, Never> {
        basePublishers.events.keepAlive(self)
    }
    
    /// Returns a publisher emitting a new value every time event of the given type is observed.
    /// - Parameter eventType: An event type that will be observed.
    /// - Returns: A publisher emitting a new value every time event of the given type is observed.
    public func eventPublisher<T: Event>(_ eventType: T.Type) -> AnyPublisher<T, Never> {
        allEventsPublisher
            .compactMap { $0 as? T }
            .eraseToAnyPublisher()
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// A backing subject for `allEventsPublisher`.
        let events = PassthroughSubject<Event, Never>()
                
        /// Creates a new `BasePublishers` instance with the provided controller.
        init(controller: EventsController) {
            controller.multicastDelegate.additionalDelegates.append(self)
        }
    }
}

@available(iOS 13, *)
extension EventsController.BasePublishers: EventsControllerDelegate {
    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        events.send(event)
    }
}
