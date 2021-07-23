//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class EventsController_Tests: StressTestCase {
    var client: ChatClient!
    var controller: EventsController!
    var callbackQueueID: UUID!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        client = _ChatClient.mock
        callbackQueueID = UUID()
        controller = EventsController(notificationCenter: client.eventNotificationCenter)
        controller.callbackQueue = .testQueue(withId: callbackQueueID)
    }
    
    override func tearDown() {
        callbackQueueID = nil
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
        }
        
        super.tearDown()
    }
    
    // MARK: - Lifecycle
    
    func test_whenDelegateHasStrongReferenceToController_thereIsNoRetainCycle() {
        class Delegate_Mock: EventsControllerDelegate {
            var controller: EventsController?
            
            func eventsController(
                _ controller: EventsController,
                didReceiveEvent event: Event
            ) {}
        }

        // Create a mock delegate.
        var delegate: Delegate_Mock? = Delegate_Mock()
        
        // Create cyclic reference between delegate and controller.
        delegate?.controller = controller
        controller.delegate = delegate
        
        // Assert there is no retain cycle.
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&delegate)
        }
    }
    
    // MARK: - Event propagation
    
    func test_whenEventsNotificationIsObserved_eventIsForwardedToDelegate() {
        class Delegate_Mock: QueueAwareDelegate, EventsControllerDelegate {
            @Atomic var events: [Event] = []
            
            func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
                events.append(event)
                validateQueue()
            }
        }

        // Create and set the delegate.
        let delegate = Delegate_Mock(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        let events = [
            TestMemberEvent.unique,
            TestMemberEvent.unique,
            TestMemberEvent.unique
        ]
        
        // Simulate incoming events.
        for event in events {
            let notification = Notification(newEventReceived: event, sender: self)
            client.eventNotificationCenter.post(notification)
        }
        
        // Assert the events are received.
        AssertAsync.willBeEqual(
            delegate.events.compactMap { $0 as? TestMemberEvent }, events
        )
    }
}
