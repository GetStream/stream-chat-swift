//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatConnectionController_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient!
    private var controller: ChatConnectionController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = ChatClient.mock
        controller = ChatConnectionController(client: client, environment: env.connectionControllerEnvironment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        controllerCallbackQueueID = nil
        client.mockAPIClient.cleanUp()
        env.chatClientUpdater?.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        super.tearDown()
    }
    
    // MARK: Controller

    func test_initialState_whenLocalDataIsFetched() throws {
        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)
        
        // Check the initial connection status.
        XCTAssertEqual(controller.connectionStatus, .initialized)
    }
    
    // MARK: - Delegate
    
    func test_delegate_isAssignedCorrectly() {
        // Set the delegate
        let delegate = ConnectionController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }
    
    func test_delegate_isReferencedWeakly() {
        // Create the delegate
        var delegate: ConnectionController_Delegate? = .init(expectedQueueId: callbackQueueID)
        
        // Set the delegate
        controller.delegate = delegate
        
        // Stop keeping a delegate alive
        delegate = nil
        
        // Assert delegate is deallocated
        XCTAssertNil(controller.delegate)
    }
    
    func test_delegate_isNotifiedAboutConnectionStatusChanges() {
        // Set the delegate
        let delegate = ConnectionController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Assert no connection status changes received so far
        XCTAssertTrue(delegate.didUpdateConnectionStatus_statuses.isEmpty)
        
        // Simulate connection status updates.
        client.webSocketClient?.simulateConnectionStatus(.connecting)
        client.webSocketClient?.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert updates are received
        AssertAsync.willBeEqual(delegate.didUpdateConnectionStatus_statuses, [.connecting, .connected])
    }

    // MARK: - Connect

    func test_connect_callsClientUpdater_and_propagatesTheResult() {
        for error in [nil, TestError()] {
            // Simulate `connect` and capture the result.
            var connectCompletionCalled = false
            var connectCompletionError: Error?
            controller.connect { [callbackQueueID] error in
                AssertTestQueue(withId: callbackQueueID)
                connectCompletionError = error
                connectCompletionCalled = true
            }

            // Assert the `chatClientUpdater` is called.
            XCTAssertTrue(env.chatClientUpdater.connect_called)
            // The completion hasn't been called yet.
            XCTAssertFalse(connectCompletionCalled)

            // Simulate `chatClientUpdater` result.
            env.chatClientUpdater.connect_completion!(error)
            // Wait for completion to be called.
            AssertAsync.willBeTrue(connectCompletionCalled)

            // Assert `error` is propagated.
            XCTAssertEqual(connectCompletionError as? TestError, error)
        }
    }

    // MARK: - Disconnect

    func test_disconnect_callsClientUpdater() {
        // Simulate `disconnect`.
        controller.disconnect()

        // Assert the `chatClientUpdater` is called.
        XCTAssertEqual(env.chatClientUpdater.disconnect_source, .userInitiated)
        XCTAssertTrue(env.chatClientUpdater.disconnect_called)
    }
}

private class TestEnvironment {
    var chatClientUpdater: ChatClientUpdater_Mock!

    lazy var connectionControllerEnvironment: ChatConnectionController
        .Environment = .init(chatClientUpdaterBuilder: { [unowned self] in
            self.chatClientUpdater = ChatClientUpdater_Mock(client: $0)
            return self.chatClientUpdater!
        })
}
