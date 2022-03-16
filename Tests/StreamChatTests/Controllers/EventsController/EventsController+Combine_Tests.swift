//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class EventsController_Combine_Tests: iOS13TestCase {
    var controller: EventsController!
    var notificationCenter: EventNotificationCenter!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        
        notificationCenter = EventNotificationCenterMock(database: DatabaseContainerMock())
        controller = EventsController(notificationCenter: notificationCenter)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        
        AssertAsync {
            Assert.canBeReleased(&notificationCenter)
            Assert.canBeReleased(&controller)
        }

        super.tearDown()
    }
    
    // MARK: - Lifecycle
    
    func test_allEventsPublisher_keepsControllerAlive() {
        // Subscribe on all events.
        controller
            .allEventsPublisher
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Keep only weak reference to the controller.
        weak var eventsController = controller
        controller = nil
        
        // Assert controller is kept alive by the publisher.
        AssertAsync.staysTrue(eventsController != nil)
    }
    
    func test_concreteEventPublisher_keepsControllerAlive() {
        // Subscribe on concrete events.
        controller
            .eventPublisher(Event1.self)
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Keep only weak reference to the controller.
        weak var eventsController = controller
        controller = nil
        
        // Assert controller is kept alive by the publisher.
        AssertAsync.staysTrue(eventsController != nil)
    }
    
    // MARK: - Event propagation
    
    func test_whenEventsArePosted_allEventsPublisherReceivesThem() {
        // Create recording
        var recording = Record<Event, Never>.Recording()
        
        // Setup the observation chain
        controller
            .allEventsPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Simulate incoming events.
        let event1 = Event1()
        let event2 = Event2()
        let events: [Event] = [event1, event2]
        
        for event in events {
            let notification = Notification(newEventReceived: event, sender: self)
            notificationCenter.post(notification)
        }
        
        // Assert all events are delivered.
        AssertAsync {
            Assert.willBeEqual(recording.output.count, events.count)
            Assert.willBeEqual(recording.output.first as? Event1, event1)
            Assert.willBeEqual(recording.output.last as? Event2, event2)
        }
    }
    
    func test_whenEventsArePosted_concreteEventPublishersReceiveThem() {
        // Setup `Event1` observation chain
        var recording1 = Record<Event1, Never>.Recording()
        controller
            .eventPublisher(Event1.self)
            .sink(receiveValue: { recording1.receive($0) })
            .store(in: &cancellables)
        
        // Setup `Event2` observation chain
        var recording2 = Record<Event2, Never>.Recording()
        controller
            .eventPublisher(Event2.self)
            .sink(receiveValue: { recording2.receive($0) })
            .store(in: &cancellables)
        
        // Simulate incoming events of different types.
        let event1 = Event1()
        let event2 = Event2()
        let events: [Event] = [event1, event2]
        
        for event in events {
            let notification = Notification(newEventReceived: event, sender: self)
            notificationCenter.post(notification)
        }
        
        // Assert both observers receive all events.
        AssertAsync {
            Assert.willBeEqual(recording1.output, [event1])
            Assert.willBeEqual(recording2.output, [event2])
        }
    }
}

private struct Event1: Event, Equatable {
    let value: Int = .random(in: 0..<1000)
}

private struct Event2: Event, Equatable {
    let value: String = .unique
}
