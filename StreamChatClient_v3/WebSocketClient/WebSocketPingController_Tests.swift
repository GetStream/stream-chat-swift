//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class WebSocketPingController_Tests: XCTestCase {
    var time: VirtualTime!
    var pingController: WebSocketPingController!
    var pingCount = 0
    var disconnectCount = 0
    
    override func setUp() {
        super.setUp()
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        pingCount = 0
        disconnectCount = 0
        
        pingController = .init(timerType: VirtualTimeTimer.self, timerQueue: .main)
        pingController.delegate = self
    }
    
    func test_startStopPingTimer() throws {
        // Checks ping timer doesn't work until it get the connect state is connected.
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval + 1)
        XCTAssertEqual(0, pingCount)
        
        // Send connection state as connected and check if a ping was send after ping timer time interval.
        pingController.connectionStateDidChange(.connected(connectionId: .unique))
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval)
        XCTAssertEqual(1, pingCount)
        
        // Send connection state as not connected and check if a ping was not send after ping timer time interval.
        pingController.connectionStateDidChange(.waitingForConnectionId)
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval + 1)
        XCTAssertEqual(1, pingCount) // The counter should be still the same value.
    }
    
    func test_pingPongReconnect() throws {
        // Send connection state as connected to start the ping timer.
        pingController.connectionStateDidChange(.connected(connectionId: .unique))
        
        // Send ping.
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval)
        XCTAssertEqual(1, pingCount)
        // Send pong.
        pingController.pongRecieved()
        // Checks it didn't call disconnect after a pong timeout time interval.
        time.run(numberOfSeconds: WebSocketPingController.pongTimeoutTimeInterval)
        XCTAssertEqual(0, disconnectCount)
        
        // Send ping again.
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval)
        XCTAssertEqual(2, pingCount)
        // Don't send pong and `disconnectCount` should be increased by 1 after a pong timeout time interval.
        time.run(numberOfSeconds: WebSocketPingController.pongTimeoutTimeInterval)
        XCTAssertEqual(1, disconnectCount)
    }
}

extension WebSocketPingController_Tests: WebSocketPingControllerDelegate {
    func sendPing() {
        pingCount += 1
    }
    
    func disconnectOnNoPongReceived() {
        disconnectCount += 1
    }
}
