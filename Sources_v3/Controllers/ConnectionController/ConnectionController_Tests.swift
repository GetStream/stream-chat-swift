//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class ConnectionController_Tests: StressTestCase {
    private var client: ChatClient!
    private var delegateMock: ConnectionControllerDelegateMock!
    private var controller: ConnectionController!
    
    override func setUp() {
        super.setUp()
        client = Client.mock
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&controller)
        super.tearDown()
    }
    
    func test_statusUpdates() {
        // Setup the connection controller without callback queue.
        delegateMock = .init()
        controller = client.connectionController()
        controller.delegate = delegateMock
        
        // Check the initial connection status.
        XCTAssertEqual(controller.connectionStatus, .disconnected(error: nil))
        
        // Change the connection status.
        client.webSocketClient.simulateConnectionStatus(.connecting)
        // Check the current connection status.
        XCTAssertEqual(controller.connectionStatus, .connecting)
        
        client.webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        XCTAssertEqual(delegateMock.statuses, [.connecting, .connected])
    }
    
    func test_statusUpdatesWithCustomCallbackQueue() throws {
        // Setup the connection controller with a custom callback queue.
        let controllerCallbackQueueId = UUID()
        delegateMock = .init()
        delegateMock.expectedQueueId = controllerCallbackQueueId
        controller = client.connectionController(callbackQueue: .testQueue(withId: controllerCallbackQueueId))
        controller.delegate = delegateMock
        
        // Change the connection status and check it.
        client.webSocketClient.simulateConnectionStatus(.connecting)
        XCTAssertEqual(controller.connectionStatus, .connecting)
        
        client.webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        // Check the current status with a new value.
        XCTAssertEqual(controller.connectionStatus, .connected)
        
        // Check delegate statuses.
        AssertAsync.willBeEqual(delegateMock.statuses, [.connecting, .connected])
    }
    
    func test_multipleControllers() {
        delegateMock = .init()
        var controller1: ConnectionController? = client.connectionController()
        let controller2 = client.connectionController()
        controller1?.delegate = delegateMock
        controller2.delegate = delegateMock
        
        client.webSocketClient.simulateConnectionStatus(.connecting)
        XCTAssertEqual(delegateMock.statuses, [.connecting, .connecting])
        controller1 = nil
        
        client.webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        AssertAsync.willBeEqual(delegateMock.statuses, [.connecting, .connecting, .connected])
    }
    
    func test_weakDelegate() {
        delegateMock = .init()
        controller = client.connectionController()
        controller.delegate = delegateMock
        delegateMock = nil
        XCTAssertNil(controller.delegate)
    }
}

private class ConnectionControllerDelegateMock: QueueAwareDelegate, ConnectionControllerDelegate {
    @Atomic var statuses = [ConnectionStatus]()
    
    func controller<ExtraData: ExtraDataTypes>(
        _ controller: ConnectionControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        validateQueue()
        _statuses { $0.append(status) }
    }
}
