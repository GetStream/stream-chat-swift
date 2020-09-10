//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

@available(iOS 13, *)
class ConnectionController_SwiftUI_Tests: iOS13TestCase {
    var controller: ConnectionController!
    
    override func setUp() {
        super.setUp()
        controller = ConnectionController(client: .mock)
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&controller)
        super.tearDown()
    }
    
    func test_observableObject() throws {
        let observableObject = controller.observableObject
        
        // Check the initial value.
        XCTAssertEqual(observableObject.connectionStatus, .disconnected(error: nil))
        
        // Check a new value.
        controller.client.webSocketClient.simulateConnectionStatus(.connecting)
        XCTAssertEqual(observableObject.connectionStatus, .connecting)
    }
}
