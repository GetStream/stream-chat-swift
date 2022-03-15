//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class InternetConnection_Tests: XCTestCase {
    var monitor: InternetConnectionMonitorMock!
    var internetConnection: InternetConnection!
    
    override func setUp() {
        super.setUp()
        monitor = InternetConnectionMonitorMock()
        internetConnection = InternetConnection(monitor: monitor)
    }
    
    func test_internetConnection_init() {
        // Assert status matches ther monitor
        XCTAssertEqual(internetConnection.status, monitor.status)
        
        // Assert internet connection is set as a delegate
        XCTAssertTrue(monitor.delegate === internetConnection)
    }
    
    func test_internetConnection_postsStatusAndAvailabilityNotifications_whenAvailabilityChanges() {
        // Set unavailable status
        monitor.status = .unavailable

        // Create new status
        let newStatus: InternetConnection.Status = .available(.great)
        
        // Set up expectations for notifications
        let notificationExpectations = [
            expectation(
                forNotification: .internetConnectionStatusDidChange,
                object: internetConnection,
                handler: { $0.internetConnectionStatus == newStatus }
            ),
            expectation(
                forNotification: .internetConnectionAvailabilityDidChange,
                object: internetConnection,
                handler: { $0.internetConnectionStatus == newStatus }
            )
        ]
        
        // Simulate status update
        monitor.status = newStatus
        
        // Assert status is updated
        XCTAssertEqual(internetConnection.status, newStatus)
        
        // Assert both notifications are posted
        wait(for: notificationExpectations, timeout: defaultTimeout)
    }
    
    func test_internetConnection_postsStatusNotification_whenQualityChanges() {
        // Set status
        monitor.status = .available(.constrained)

        // Create status with another quality
        let newStatus: InternetConnection.Status = .available(.great)

        // Set up expectation for a notification
        let notificationExpectation = expectation(
            forNotification: .internetConnectionStatusDidChange,
            object: internetConnection,
            handler: { $0.internetConnectionStatus == newStatus }
        )
        
        // Simulate quality update
        monitor.status = newStatus
        
        // Assert status is updated
        XCTAssertEqual(internetConnection.status, newStatus)
        
        // Assert both notifications are posted
        wait(for: [notificationExpectation], timeout: defaultTimeout)
    }

    func test_internetConnection_stopsMonitorWhenDeinited() throws {
        assert(monitor.isStarted)
        
        internetConnection = nil
        XCTAssertFalse(monitor.isStarted)
    }
}
