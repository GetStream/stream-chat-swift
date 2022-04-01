//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class ChatConnectionController_SwiftUI_Tests: iOS13TestCase {
    var connectionController: ChatConnectionControllerMock!
    
    override func setUp() {
        super.setUp()
        connectionController = ChatConnectionControllerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&connectionController)
        connectionController = nil
        super.tearDown()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        connectionController.connectionStatus_simulated = .initialized
        
        let observableObject = connectionController.observableObject
        
        XCTAssertEqual(observableObject.connectionStatus, connectionController.connectionStatus)
    }
    
    func test_observableObject_reactsToDelegateConnectionStatusChangesCallback() {
        let observableObject = connectionController.observableObject
        
        // Simulate connection status change
        let newStatus: ConnectionStatus = .connected
        connectionController.delegateCallback {
            $0.connectionController(
                self.connectionController,
                didUpdateConnectionStatus: newStatus
            )
        }
        
        AssertAsync.willBeEqual(observableObject.connectionStatus, newStatus)
    }
}

final class ChatConnectionControllerMock: ChatConnectionController {
    var connectionStatus_simulated: ConnectionStatus?
    override var connectionStatus: ConnectionStatus {
        connectionStatus_simulated ?? super.connectionStatus
    }
    
    init() {
        super.init(client: .mock)
    }
}
