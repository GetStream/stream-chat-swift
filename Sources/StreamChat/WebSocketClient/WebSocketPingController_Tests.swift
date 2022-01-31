//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class WebSocketPingController_Tests: XCTestCase {
    var time: VirtualTime!
    var pingController: WebSocketPingController!
    private var delegate: TestWebSocketPingControllerDelegate!
    
    override func setUp() {
        super.setUp()
        time = VirtualTime()
        VirtualTimeTimer.time = time
        pingController = .init(timerType: VirtualTimeTimer.self, timerQueue: .main)
        
        delegate = TestWebSocketPingControllerDelegate()
        pingController.delegate = delegate
    }
    
    override func tearDown() {
        time = nil
        VirtualTimeTimer.time = nil
        pingController = nil
        delegate = nil
        super.tearDown()
    }
    
    func test_sendPing_called_whenTheConnectionIsConnected() throws {
        assert(delegate.sendPing_calledCount == 0)
        
        // Check `sendPing` is not called when the connection is not connected
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval + 1)
        XCTAssertEqual(delegate.sendPing_calledCount, 0)
        
        // Set the connection state as connected
        pingController.connectionStateDidChange(.connected(connectionId: .unique))
        
        // Simulate time passed 3x pingTimeInterval (+1 for margin errors)
        time.run(numberOfSeconds: 3 * (WebSocketPingController.pingTimeInterval + 1))
        XCTAssertEqual(delegate.sendPing_calledCount, 3)
        
        let oldPingCount = delegate.sendPing_calledCount
        
        // Set the connection state to not connected and check `sendPing` is no longer called
        pingController.connectionStateDidChange(.waitingForConnectionId)
        time.run(numberOfSeconds: 3 * (WebSocketPingController.pingTimeInterval + 1))
        XCTAssertEqual(delegate.sendPing_calledCount, oldPingCount)
    }
    
    func test_disconnectOnNoPongReceived_called_whenNoPongReceived() throws {
        // Set the connection state as connected
        pingController.connectionStateDidChange(.connected(connectionId: .unique))
        
        assert(delegate.sendPing_calledCount == 0)
        
        // Simulate time passing and wait for `sendPing` call
        while delegate.sendPing_calledCount != 1 {
            time.run(numberOfSeconds: 1)
        }
        
        // Simulate pong received
        pingController.pongReceived()
        
        // Simulate time passed pongTimeoutTimeInterval + 1 and check disconnectOnNoPongReceived wasn't called
        assert(delegate.disconnectOnNoPongReceived_calledCount == 0)
        time.run(numberOfSeconds: WebSocketPingController.pongTimeoutTimeInterval + 1)
        XCTAssertEqual(delegate.disconnectOnNoPongReceived_calledCount, 0)
        
        assert(delegate.sendPing_calledCount == 1)
        
        // Simulate time passing and wait for another `sendPing` call
        while delegate.sendPing_calledCount != 2 {
            time.run(numberOfSeconds: 1)
        }
        
        // Simulate time passed pongTimeoutTimeInterval + 1 without receiving a pong
        assert(delegate.disconnectOnNoPongReceived_calledCount == 0)
        time.run(numberOfSeconds: WebSocketPingController.pongTimeoutTimeInterval + 1)
        
        // `disconnectOnNoPongReceived` should be called
        XCTAssertEqual(delegate.disconnectOnNoPongReceived_calledCount, 1)
    }
}

private class TestWebSocketPingControllerDelegate: WebSocketPingControllerDelegate {
    var sendPing_calledCount = 0
    var disconnectOnNoPongReceived_calledCount = 0
    func sendPing() {
        sendPing_calledCount += 1
    }
    
    func disconnectOnNoPongReceived() {
        disconnectOnNoPongReceived_calledCount += 1
    }
}
