//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class InternetConnection_Tests: XCTestCase {
    var monitor: InternetConnectionMonitorMock!
    var internetConnection: InternetConnection!
    
    override func setUp() {
        super.setUp()
        monitor = InternetConnectionMonitorMock()
        internetConnection = InternetConnection(monitor: monitor)
    }

    func test_internetConnection_startsMonitoringAutomatically() throws {
        XCTAssertTrue(monitor.isStarted)
        
        // Set up expectation for a notification
        let notificationExpectation = expectation(
            forNotification: .internetConnectionStatusDidChange,
            object: internetConnection
        ) {
            $0.internetConnectionStatus == .available(.great)
        }
        
        // Simulate status update
        monitor.status = .available(.great)
        
        XCTAssertEqual(internetConnection.status, .available(.great))
        wait(for: [notificationExpectation], timeout: 1)
    }

    func test_internetConnection_stopsMonitorWhenDeinited() throws {
        assert(monitor.isStarted)
        
        internetConnection = nil
        XCTAssertFalse(monitor.isStarted)
    }
}

class InternetConnectionMock: InternetConnection {
    private(set) var monitorMock: InternetConnectionMonitorMock!
    
    init(notificationCenter: NotificationCenter = .default) {
        let monitor = InternetConnectionMonitorMock()
        super.init(notificationCenter: notificationCenter, monitor: monitor)
        monitorMock = monitor
    }
}

class InternetConnectionMonitorMock: InternetConnectionMonitor {
    weak var delegate: InternetConnectionDelegate?
    
    var status: InternetConnection.Status = .unknown {
        didSet {
            delegate?.internetConnectionStatusDidChange(status: status)
        }
    }
    
    var isStarted = false
    
    func start() {
        isStarted = true
        status = .available(.great)
    }
    
    func stop() {
        isStarted = false
        status = .unknown
    }
}
