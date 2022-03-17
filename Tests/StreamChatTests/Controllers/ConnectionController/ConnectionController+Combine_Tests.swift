//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class ChatConnectionController_Combine_Tests: iOS13TestCase {
    var connectionController: ChatConnectionControllerMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        connectionController = ChatConnectionControllerMock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        connectionController = nil
        super.tearDown()
    }
    
    func test_connectionStatusPublisher() throws {
        // Setup Recording publishers
        var recording = Record<ConnectionStatus, Never>.Recording()
        
        // Setup the chain
        connectionController.connectionStatusPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatConnectionControllerMock? = connectionController
        connectionController = nil
        
        // Simulate connection status update
        let newStatus: ConnectionStatus = .connected
        controller?.delegateCallback { $0.connectionController(controller!, didUpdateConnectionStatus: newStatus) }
        
        // Assert initial value as well as the update are received
        AssertAsync.willBeEqual(recording.output, [.initialized, newStatus])
    }
}
