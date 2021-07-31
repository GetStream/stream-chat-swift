//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class EventsController_SwiftUI_Tests: iOS13TestCase {
    var controller: EventsController!
    var notificationCenter: EventNotificationCenter!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        notificationCenter = EventNotificationCenterMock(
            database: DatabaseContainerMock()
        )
        controller = EventsController(
            notificationCenter: notificationCenter
        )
    }
    
    override func tearDown() {
        AssertAsync {
            Assert.canBeReleased(&notificationCenter)
            Assert.canBeReleased(&controller)
        }
        
        super.tearDown()
    }
    
    // MARK: - Lifecycle
    
    func test_observableObject_keepsControllerAlive() {
        // Get observable object
        let observableObject = controller.observableObject
        
        // Keep only weak reference to controller
        weak var weakController = controller
        controller = nil
        
        // Controller is being kept alive by observable object.
        AssertAsync.staysTrue(weakController != nil)
        
        // Simulate access to observable object so it's not deallocated.
        _ = observableObject
    }
    
    func test_observableObject_doesNotCreateRetainCycle() {
        // Create observable object
        var observableObject: EventsController.ObservableObject? = controller.observableObject
        
        // Assert observable object does not create retain cycle.
        AssertAsync {
            Assert.canBeReleased(&observableObject)
            Assert.canBeReleased(&controller)
        }
    }
    
    // MARK: - Initial state
    
    func test_whenObservableObjectIsCreated_lastObservedEventIsNil() {
        // Assert last observed event is nil initially
        XCTAssertNil(controller.observableObject.mostRecentEvent)
    }
    
    // MARK: - Event propagation
    
    func test_whenEventsIsPosted_observableObjectReceivesIt() {
        // Get observable object
        let observableObject = controller.observableObject
        
        // Simulate incoming event
        let event = TestMemberEvent.unique
        let notification = Notification(newEventReceived: event, sender: self)
        notificationCenter.post(notification)
        
        // Assert event is forwarded to observable object.
        AssertAsync.willBeEqual(observableObject.mostRecentEvent as? TestMemberEvent, event)
    }
}
