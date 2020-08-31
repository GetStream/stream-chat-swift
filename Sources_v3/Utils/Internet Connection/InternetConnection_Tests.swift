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

    func test_internetConnection_start() throws {
        let notificationExpectation = expectation(forNotification: .internetConnectionStatusDidChange, object: nil) {
            $0.userInfo?[InternetConnection.statusUserInfoKey] as? InternetConnection.Status == .available(.great)
        }
        
        XCTAssertEqual(internetConnection.status, .unknown)
        internetConnection.start()
        XCTAssertTrue(monitor.isStarted)
        XCTAssertEqual(internetConnection.status, .available(.great))
        wait(for: [notificationExpectation], timeout: 5)
    }

    func test_internetConnection_stop() throws {
        var notificationStatuses = [InternetConnection.Status]()
        
        let notificationExpectation = expectation(forNotification: .internetConnectionStatusDidChange, object: nil) {
            if let status = $0.userInfo?[InternetConnection.statusUserInfoKey] as? InternetConnection.Status {
                notificationStatuses.append(status)
            }
            
            return true
        }
        
        internetConnection.start()
        XCTAssertTrue(monitor.isStarted)
        internetConnection.stop()
        XCTAssertFalse(monitor.isStarted)
        XCTAssertEqual(internetConnection.status, .unknown)
        wait(for: [notificationExpectation], timeout: 5)
        XCTAssertEqual(notificationStatuses, [.available(.great), .unknown])
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
