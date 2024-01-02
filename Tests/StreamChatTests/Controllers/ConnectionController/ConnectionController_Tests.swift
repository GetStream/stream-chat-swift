//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatConnectionController_Tests: XCTestCase {
    private var webSocketClient: WebSocketClient_Mock!
    private var connectionRepository: ConnectionRepository_Mock!
    private var client: ChatClient!
    private var controller: ChatConnectionController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        client = ChatClient.mock
        webSocketClient = WebSocketClient_Mock(eventNotificationCenter: client.eventNotificationCenter)
        connectionRepository = ConnectionRepository_Mock()
        controller = ChatConnectionController(
            connectionRepository: connectionRepository,
            webSocketClient: webSocketClient,
            client: client
        )
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    override func tearDown() {
        controllerCallbackQueueID = nil
        client.mockAPIClient.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
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

            connectionRepository.connectResult = error.map { .failure($0) } ?? .success(())

            var connectCompletionError: Error?
            let expectation = self.expectation(description: "Connect completes")
            controller.connect { [callbackQueueID] error in
                AssertTestQueue(withId: callbackQueueID)
                connectCompletionError = error
                expectation.fulfill()
            }

            // Assert the `chatClientUpdater` is called.
            XCTAssertCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)

            waitForExpectations(timeout: defaultTimeout)

            // Assert `error` is propagated.
            XCTAssertEqual(connectCompletionError as? TestError, error)
        }
    }

    // MARK: - Disconnect

    func test_disconnect_callsClientUpdater() {
        // Simulate `disconnect`.
        controller.disconnect()

        // Assert the `chatClientUpdater` is called.
        XCTAssertEqual(connectionRepository.disconnectSource, .userInitiated)
        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: connectionRepository)
    }
}
