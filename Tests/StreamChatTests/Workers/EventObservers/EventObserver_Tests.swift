//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class EventObserver_Tests: XCTestCase {
    var notificationCenter: NotificationCenter!
    var eventToDeliver: HealthCheckEvent!
    var observer: EventObserver?
    var eventNotification: Notification {
        .init(newEventReceived: eventToDeliver, sender: self)
    }

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        notificationCenter = NotificationCenter()
        eventToDeliver = HealthCheckEvent(connectionId: .unique)
    }

    override func tearDown() {
        notificationCenter = nil
        eventToDeliver = nil
        observer = nil
        
        super.tearDown()
    }

    // MARK: - Calling back tests

    func test_callbackIsNotCalled_ifObserverIsDeallocated() {
        var callbackExecutionCount = 0

        // Create observer and count callback executions
        observer = .init(
            notificationCenter: notificationCenter,
            transform: { $0 as? HealthCheckEvent },
            callback: { _ in callbackExecutionCount += 1 }
        )

        // Send event notification
        notificationCenter.post(eventNotification)
        // Assert callback is called
        AssertAsync.willBeEqual(callbackExecutionCount, 1)

        // Release the observer
        observer = nil

        // Send event notification
        notificationCenter.post(eventNotification)
        // Assert callback is not called one more time
        AssertAsync.staysEqual(callbackExecutionCount, 1)
    }

    func test_callbackIsCalled_ifEventCastSucceeds() {
        var receivedEvent: HealthCheckEvent?

        // Create observer and catch event coming to callback
        observer = EventObserver(
            notificationCenter: notificationCenter,
            transform: { $0 as? HealthCheckEvent },
            callback: { receivedEvent = $0 }
        )

        // Send event notification
        notificationCenter.post(eventNotification)

        // Assert event is received
        AssertAsync.willBeEqual(receivedEvent?.connectionId, eventToDeliver.connectionId)
    }

    func test_callbackIsNotCalled_ifEventCastFails() {
        var receivedEvent: Event?

        // Create observer and catch event coming to callback
        observer = EventObserver(
            notificationCenter: notificationCenter,
            transform: { $0 as? MemberAddedEvent },
            callback: { receivedEvent = $0 }
        )

        // Send event notification
        notificationCenter.post(eventNotification)

        // Assert none event is received
        AssertAsync.staysTrue(receivedEvent == nil)
    }
}
