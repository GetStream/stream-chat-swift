//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class WebSocketPingController_Tests: XCTestCase {
    var time: VirtualTime!
    var pingController: WebSocketPingController!
    var pingCount = 0
    var reconnectCount = 0
    
    override func setUp() {
        super.setUp()
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        pingCount = 0
        reconnectCount = 0
        
        pingController = .init(timerType: VirtualTimeTimer.self,
                               timerQueue: .main,
                               ping: { [unowned self] in self.pingCount += 1 },
                               forceReconnect: { [unowned self] in self.reconnectCount += 1 })
    }
    
    func test_startStopPingTimer() throws {
        // Checks ping timer doesn't work until
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval + 1)
        XCTAssertEqual(0, pingCount)
        
        pingController.connectionStateDidChange(.connected(connectionId: .unique))
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval)
        XCTAssertEqual(1, pingCount)
        
        pingController.connectionStateDidChange(.waitingForConnectionId)
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval + 1)
        XCTAssertEqual(1, pingCount)
    }
    
    func test_pingPongReconnect() throws {
        pingController.connectionStateDidChange(.connected(connectionId: .unique))
        
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval)
        XCTAssertEqual(1, pingCount)
        pingController.pongRecieved()
        time.run(numberOfSeconds: WebSocketPingController.pongTimeoutTimeInterval)
        XCTAssertEqual(0, reconnectCount)
        
        time.run(numberOfSeconds: WebSocketPingController.pingTimeInterval)
        XCTAssertEqual(2, pingCount)
        time.run(numberOfSeconds: WebSocketPingController.pongTimeoutTimeInterval)
        XCTAssertEqual(1, reconnectCount)
    }
}
