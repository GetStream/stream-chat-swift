//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatClient
import XCTest

@available(iOS 13, *)
class ConnectionController_Combine_Tests: iOS13TestCase {
    var controller: ConnectionController!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        controller = ConnectionController(client: .mock)
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&controller)
        super.tearDown()
    }
    
    func test_connectionStatusPublisher() throws {
        // Setup Recording publishers
        var recording = Record<ConnectionStatus, Never>.Recording()
        
        controller.connectionStatusPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        controller.client.webSocketClient.simulateConnectionStatus(.connecting)
        XCTAssertEqual(recording.output, [.disconnected(error: nil), .connecting])
    }
}
