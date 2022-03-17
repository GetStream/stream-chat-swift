//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventsController_Tests: XCTestCase {
    var client: ChatClient!
    var controller: EventsController!
    var callbackQueueID: UUID!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        client = ChatClient.mock
        callbackQueueID = UUID()
        controller = EventsController(notificationCenter: client.eventNotificationCenter)
        controller.callbackQueue = .testQueue(withId: callbackQueueID)
    }
    
    override func tearDown() {
        callbackQueueID = nil
        controller = nil
        client = nil
        
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
    
    func test_whenEventsNotificationIsObserved_onlyEventsThatShouldBeProcessed_areForwardedToDelegate() {
        class EventsControllerMock: EventsController {
            lazy var shouldProcessEventMockFunc = MockFunc.mock(for: shouldProcessEvent)

            override func shouldProcessEvent(_ event: Event) -> Bool {
                shouldProcessEventMockFunc.callAndReturn(event)
            }
        }

        // Create mock controller.
        let controller = EventsControllerMock(notificationCenter: client.eventNotificationCenter)
        controller.callbackQueue = .testQueue(withId: callbackQueueID)
        
        // Create and set the delegate.
        let delegate = TestEventsControllerDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Create `event -> should be processed` mapping.
        let events: [TestMemberEvent: Bool] = [
            TestMemberEvent.unique: true,
            TestMemberEvent.unique: false,
            TestMemberEvent.unique: true,
            TestMemberEvent.unique: false
        ]
        
        for (event, shouldBeProcessed) in events {
            // Change the value returned by `shouldProcessEvent` func.
            controller.shouldProcessEventMockFunc.returns(shouldBeProcessed)
            
            // Simulate incoming event.
            let notification = Notification(newEventReceived: event, sender: self)
            client.eventNotificationCenter.post(notification)
        }
        
        AssertAsync {
            // Assert `shouldProcessEvent` is invoked for each incoming event.
            Assert.willBeEqual(controller.shouldProcessEventMockFunc.count, events.count)
            
            // Assert delegate received only events which have passed the filter
            Assert.willBeEqual(
                delegate.events.compactMap { $0 as? TestMemberEvent },
                events.compactMap { event, shouldProcess in shouldProcess ? event : nil }
            )
        }
    }
    
    func test_whenEventsNotificationIsObserved_theUnknownUserEvent_isForwardedToDelegate() {
        // Create and set the delegate.
        let delegate = TestEventsControllerDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Create `event -> should be processed` mapping.
        let event = UnknownUserEvent(type: .userBanned, userId: .unique, createdAt: Date(), payload: [:])
        
        let notification = Notification(newEventReceived: event, sender: self)
        client.eventNotificationCenter.post(notification)
        
        // Assert delegate received only events which have passed the filter
        AssertAsync.willBeEqual(
            delegate.events.compactMap { $0 as? UnknownUserEvent }, [event]
        )
    }
    
    func test_whenEventsNotificationIsObserved_theUnknownChannelEvent_isForwardedToDelegate() throws {
        // Create and set the delegate.
        let delegate = TestEventsControllerDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Create `event -> should be processed` mapping.
        let cid: ChannelId = try .init(cid: "clubid:1234")
        let event = UnknownChannelEvent(type: .channelHidden, cid: cid, userId: .unique, createdAt: Date(), payload: [:])
        
        let notification = Notification(newEventReceived: event, sender: self)
        client.eventNotificationCenter.post(notification)
        
        // Assert delegate received only events which have passed the filter
        AssertAsync.willBeEqual(
            delegate.events.compactMap { $0 as? UnknownChannelEvent }, [event]
        )
    }
}
