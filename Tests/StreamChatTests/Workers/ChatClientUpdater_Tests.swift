//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatClientUpdater_Tests: XCTestCase {
    // MARK: Disconnect

    func test_disconnect_whenClientIsPassive() {
        // Create a passive client with user session.
        let client = mockClientWithUserSession(isActive: false)

        // Create an updater.
        let updater = ChatClientUpdater(client: client)

        // Simulate `disconnect` call.
        let expectation = expectation(description: "`disconnect` completion")
        updater.disconnect {
            expectation.fulfill()
        }

        // Assert `disconnect` was not called on `webSocketClient`.
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 0)
        
        // Assert `flushRequestsQueue` is called on API client.
        XCTAssertCall("flushRequestsQueue()", on: client.mockAPIClient, times: 1)
        // Assert recovery flow is cancelled.
        XCTAssertCall("cancelRecoveryFlow()", on: client.mockSyncRepository, times: 1)
        
        // Assert completion called
        wait(for: [expectation], timeout: 0)
    }

    func test_disconnect_closesTheConnection_ifClientIsActive() {
        // Create an active client with user session.
        let client = mockClientWithUserSession()

        // Create an updater.
        let updater = ChatClientUpdater(client: client)

        // Simulate `disconnect` call.
        let expectation = expectation(description: "`disconnect` completion")
        updater.disconnect {
            expectation.fulfill()
        }

        // Assert `webSocketClient` was disconnected.
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 1)
        // Assert `flushRequestsQueue` is called on API client.
        XCTAssertCall("flushRequestsQueue()", on: client.mockAPIClient, times: 1)
        // Assert recovery flow is cancelled.
        XCTAssertCall("cancelRecoveryFlow()", on: client.mockSyncRepository, times: 1)
        
        // Simulate completed disconnection
        client.mockWebSocketClient.disconnect_completion!()
        
        // Assert completion is called
        wait(for: [expectation], timeout: 0)
        // Assert connection id is `nil`.
        XCTAssertNil(client.connectionId)
        // Assert all requests waiting for the connection-id were canceled.
        XCTAssertTrue(client.completeConnectionIdWaiters_called)
        XCTAssertNil(client.completeConnectionIdWaiters_connectionId)
    }

    func test_disconnect_whenWebSocketIsNotConnected() throws {
        // Create an active client with user session.
        let client = mockClientWithUserSession()

        // Create an updater.
        let updater = ChatClientUpdater(client: client)

        // Simulate `disconnect` call.
        updater.disconnect {}
        client.mockWebSocketClient.disconnect_completion!()
        
        // Reset state.
        client.mockWebSocketClient.disconnect_calledCounter = 0
        client.mockAPIClient.recordedFunctions.removeAll()
        client.mockSyncRepository.recordedFunctions.removeAll()

        // Simulate `disconnect` one more time.
        let expectation = expectation(description: "`disconnect` completion")
        updater.disconnect {
            expectation.fulfill()
        }

        // Assert `connect` was not called on `webSocketClient`.
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 0)
        // Assert `flushRequestsQueue` is called on API client.
        XCTAssertCall("flushRequestsQueue()", on: client.mockAPIClient, times: 1)
        // Assert recovery flow is cancelled.
        XCTAssertCall("cancelRecoveryFlow()", on: client.mockSyncRepository, times: 1)
        // Assert completion is called
        wait(for: [expectation], timeout: 0)
    }

    // MARK: Connect

    func test_connect_throwsError_ifClientIsPassive() throws {
        // Create a passive client with user session.
        let client = mockClientWithUserSession(isActive: false)

        // Create an updater.
        let updater = ChatClientUpdater(client: client)

        // Simulate `connect` call.
        let error = try waitFor { completion in
            updater.connect(completion: completion)
        }

        // Assert `ClientError.ClientIsNotInActiveMode` is propagated
        XCTAssertTrue(error is ClientError.ClientIsNotInActiveMode)
    }

    func test_connect_doesNothing_ifConnectionExist() throws {
        // Create an active client with user session.
        let client = mockClientWithUserSession()

        // Create an updater.
        let updater = ChatClientUpdater(client: client)

        // Simulate `connect` call.
        let error = try waitFor { completion in
            updater.connect(completion: completion)
        }

        // Assert `connect` completion is called without any error.
        XCTAssertNil(error)
        // Assert `connect` was not called on `webSocketClient`.
        XCTAssertEqual(client.mockWebSocketClient.connect_calledCounter, 0)
        // Assert connection id waiter was not added.
        XCTAssertEqual(client.connectionIdWaiters.count, 0)
    }

    func test_connect_callsWebSocketClient_andPropagatesNilError() {
        // Create an active client with user session.
        let client = mockClientWithUserSession()

        // Create an updater.
        let updater = ChatClientUpdater(client: client)

        // Disconnect client from web-socket.
        updater.disconnect {}
        client.mockWebSocketClient.disconnect_completion!()

        // Simulate `connect` call and catch the result.
        var connectCompletionCalled = false
        var connectCompletionError: Error?
        updater.connect {
            connectCompletionCalled = true
            connectCompletionError = $0
        }

        // Assert `webSocketClient` is asked to connect.
        XCTAssertEqual(client.mockWebSocketClient.connect_calledCounter, 1)
        // Assert new connection id waiter is added.
        XCTAssertEqual(client.connectionIdWaiters.count, 1)

        // Simulate established connection and provide `connectionId` to waiters.
        client.completeConnectionIdWaiters(connectionId: .unique)

        AssertAsync {
            // Wait for completion to be called.
            Assert.willBeTrue(connectCompletionCalled)
            // Assert completion is called without any error.
            Assert.staysTrue(connectCompletionError == nil)
        }
    }

    func test_connect_callsWebSocketClient_andPropagatesError() throws {
        for connectionError in [nil, ClientError.Unexpected()] {
            // Create an active client with user session.
            let client = mockClientWithUserSession()

            // Create an updater.
            let updater = ChatClientUpdater(client: client)

            // Disconnect client from web-socket.
            updater.disconnect {}
            client.mockWebSocketClient.disconnect_completion!()

            // Simulate `connect` call and catch the result.
            var connectCompletionCalled = false
            var connectCompletionError: Error?
            updater.connect {
                connectCompletionCalled = true
                connectCompletionError = $0
            }

            // Assert `webSocketClient` is asked to connect.
            XCTAssertEqual(client.mockWebSocketClient.connect_calledCounter, 1)
            // Assert new connection id waiter is added.
            XCTAssertEqual(client.connectionIdWaiters.count, 1)

            if let error = connectionError {
                // Simulate web socket `disconnected` state initiated by the server with the specific error.
                client.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .serverInitiated(error: error)))
            }

            // Simulate error while establishing a connection.
            client.completeConnectionIdWaiters(connectionId: nil)

            // Wait completion is called.
            AssertAsync.willBeTrue(connectCompletionCalled)

            if connectionError == nil {
                // Assert `ClientError.ConnectionNotSuccessful` error is propagated.
                XCTAssertTrue(connectCompletionError is ClientError.ConnectionNotSuccessful)
            } else {
                // Assert `ClientError.ConnectionNotSuccessful` error with underlaying error is propagated.
                let clientError = connectCompletionError as! ClientError.ConnectionNotSuccessful
                XCTAssertTrue(clientError.underlyingError is ClientError.Unexpected)
            }
        }
    }

    func test_connect_callsCompletion_ifUpdaterIsDeallocated() throws {
        for connectionId in [nil, String.unique] {
            // Create an active client with user session.
            let client = mockClientWithUserSession()

            // Create an updater.
            var updater: ChatClientUpdater? = .init(client: client)

            // Disconnect client from web-socket.
            updater?.disconnect {}
            client.mockWebSocketClient.disconnect_completion!()

            // Simulate `connect` call and catch the result.
            var connectCompletionCalled = false
            var connectCompletionError: Error?
            updater?.connect {
                connectCompletionCalled = true
                connectCompletionError = $0
            }

            // Remove strong ref to updater.
            updater = nil

            // Simulate established connection.
            client.completeConnectionIdWaiters(connectionId: connectionId)

            // Wait for completion to be called.
            AssertAsync.willBeTrue(connectCompletionCalled)

            if connectionId == nil {
                XCTAssertNotNil(connectCompletionError)
            } else {
                XCTAssertNil(connectCompletionError)
            }
        }
    }
    
    func test_reloadUserIfNeeded_sameUser() throws {
        // Create current user id.
        let currentUserId: UserId = .unique
        let initialToken: Token = .unique(userId: currentUserId)
        let updatedToken: Token = .unique(userId: currentUserId)

        // Create an active client with user session.
        let client = mockClientWithUserSession(token: initialToken)
        
        // Create and track channel controller
        let channelController = ChatChannelController(
            channelQuery: .init(cid: .unique),
            channelListQuery: nil,
            client: client
        )
        client.trackChannelController(channelController)
        
        // Create and track channel list controller
        let channelListController = ChatChannelListController(
            query: .init(filter: .exists(.cid)),
            client: client
        )
        client.trackChannelListController(channelListController)
        
        // Create an updater.
        let updater = ChatClientUpdater(client: client)
        
        // Save current background worker ids.
        let oldWorkerIDs = client.testBackgroundWorkerId
        
        // Simulate `reloadUserIfNeeded` call.
        var reloadUserIfNeededCompletionCalled = false
        var reloadUserIfNeededCompletionError: Error?
        updater.reloadUserIfNeeded(
            userConnectionProvider: .static(updatedToken)
        ) {
            reloadUserIfNeededCompletionCalled = true
            reloadUserIfNeededCompletionError = $0
        }
        
        // Assert current user id is valid.
        XCTAssertEqual(client.currentUserId, updatedToken.userId)
        // Assert token is valid.
        XCTAssertEqual(client.currentToken, updatedToken)
        // Assert web-socket is not disconnected
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 0)
        // Assert web-socket endpoint is valid.
        XCTAssertEqual(
            client.webSocketClient?.connectEndpoint.map(AnyEndpoint.init),
            AnyEndpoint(.webSocketConnect(userInfo: UserInfo(id: updatedToken.userId)))
        )
        // Assert `completeTokenWaiters` was called.
        XCTAssertTrue(client.completeTokenWaiters_called)
        // Assert `completeTokenWaiters` was called with updated token.
        XCTAssertEqual(client.completeTokenWaiters_token, updatedToken)
        // Assert background workers stay the same.
        XCTAssertEqual(client.testBackgroundWorkerId, oldWorkerIDs)
        // Assert database is not flushed.
        XCTAssertFalse(client.mockDatabaseContainer.removeAllData_called)
        // Assert active components are preserved
        XCTAssertTrue(client.activeChannelControllers.contains(channelController))
        XCTAssertTrue(client.activeChannelListControllers.contains(channelListController))
        
        // Assert web-socket `connect` is called.
        XCTAssertEqual(client.mockWebSocketClient.connect_calledCounter, 0)
        
        // Simulate established connection and provide `connectionId` to waiters.
        let connectionId: String = .unique
        client.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: connectionId))
        
        AssertAsync {
            // Assert completion is called.
            Assert.willBeTrue(reloadUserIfNeededCompletionCalled)
            // Assert completion is called without any error.
            Assert.staysTrue(reloadUserIfNeededCompletionError == nil)
            // Assert connection id is set.
            Assert.willBeEqual(client.connectionId, connectionId)
            // Assert connection status is updated.
            Assert.willBeEqual(client.connectionStatus, .connected)
        }
    }
    
    func test_reloadUserIfNeeded_anotherUser() throws {
        // Create current user id.
        let currentUserId: UserId = .unique
        // Create new user id.
        let newUserId: UserId = .unique
        
        let initialToken: Token = .unique(userId: currentUserId)
        let updatedToken: Token = .unique(userId: newUserId)
        
        // Create an active client with user session.
        let client = mockClientWithUserSession(token: initialToken)
        
        // Create and track channel controller
        let channelController = ChatChannelController(
            channelQuery: .init(cid: .unique),
            channelListQuery: nil,
            client: client
        )
        client.trackChannelController(channelController)
        
        // Create and track channel list controller
        let channelListController = ChatChannelListController(
            query: .init(filter: .exists(.cid)),
            client: client
        )
        client.trackChannelListController(channelListController)
        
        // Create an updater.
        let updater = ChatClientUpdater(client: client)
        
        // Save current background worker ids.
        let oldWorkerIDs = client.testBackgroundWorkerId
        
        // Simulate `reloadUserIfNeeded` call.
        var reloadUserIfNeededCompletionCalled = false
        var reloadUserIfNeededCompletionError: Error?
        updater.reloadUserIfNeeded(
            userConnectionProvider: .static(updatedToken)
        ) {
            reloadUserIfNeededCompletionCalled = true
            reloadUserIfNeededCompletionError = $0
        }
        
        // Assert `completeTokenWaiters` was called.
        XCTAssertTrue(client.completeTokenWaiters_called)
        // Assert `completeTokenWaiters` was called with `nil` token which means all
        // pending requests were cancelled.
        XCTAssertNil(client.completeTokenWaiters_token)
        // Assert current user id is valid.
        XCTAssertEqual(client.currentUserId, updatedToken.userId)
        // Assert token is valid.
        XCTAssertEqual(client.currentToken, updatedToken)
        
        // Assert web-socket is disconnected
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 1)
        XCTAssertEqual(client.mockWebSocketClient.disconnect_source, .userInitiated)
        // Assert web-socket endpoint is valid.
        XCTAssertEqual(
            client.webSocketClient?.connectEndpoint.map(AnyEndpoint.init),
            AnyEndpoint(
                .webSocketConnect(
                    userInfo: UserInfo(id: updatedToken.userId)
                )
            )
        )
        
        // Simulate disconnection completed
        client.mockWebSocketClient.disconnect_completion!()
        
        // Assert background workers are recreated since the user has changed.
        XCTAssertNotEqual(client.testBackgroundWorkerId, oldWorkerIDs)
        // Assert database was flushed.
        XCTAssertTrue(client.mockDatabaseContainer.removeAllData_called)
        // Assert active components from previous user are no longer tracked.
        XCTAssertTrue(client.activeChannelControllers.allObjects.isEmpty)
        XCTAssertTrue(client.activeChannelListControllers.allObjects.isEmpty)
        
        // Assert completion hasn't been called yet.
        XCTAssertFalse(reloadUserIfNeededCompletionCalled)
        
        // Assert web-socket `connect` is called.
        AssertAsync.willBeEqual(client.mockWebSocketClient.connect_calledCounter, 1)
        
        // Simulate established connection and provide `connectionId` to waiters.
        let connectionId: String = .unique
        client.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: connectionId))
        
        AssertAsync {
            // Assert completion is called.
            Assert.willBeTrue(reloadUserIfNeededCompletionCalled)
            // Assert completion is called without any error.
            Assert.staysTrue(reloadUserIfNeededCompletionError == nil)
            // Assert connection id is set.
            Assert.willBeEqual(client.connectionId, connectionId)
            // Assert connection status is updated.
            Assert.willBeEqual(client.connectionStatus, .connected)
        }
    }

    func test_reloadUserIfNeeded_newUser_propagatesClientIsPassiveError() throws {
        // Create `passive` client with user set.
        let client = mockClientWithUserSession(isActive: false)

        // Create `ChatClientUpdater` instance.
        let updater = ChatClientUpdater(client: client)

        // Simulate `reloadUserIfNeeded` call and catch the result.
        let error = try waitFor { completion in
            updater.reloadUserIfNeeded(userConnectionProvider: .static(.unique()), completion: completion)
        }

        // Assert `ClientError.ClientIsNotInActiveMode` is propagated.
        XCTAssertTrue(error is ClientError.ClientIsNotInActiveMode)
    }
    
    func test_reloadUserIfNeeded_newUser_propagatesClientHasBeenDeallocatedError() throws {
        // Create `passive` client with user set.
        var client: ChatClient_Mock? = mockClientWithUserSession()
        let webSocketClient = client!.mockWebSocketClient
        
        // Create `ChatClientUpdater` instance.
        let updater = ChatClientUpdater(client: client!)

        // Simulate `reloadUserIfNeeded` call and catch the result.
        var error: Error?
        updater.reloadUserIfNeeded(userConnectionProvider: .static(.unique())) {
            error = $0
        }
        
        // Deallocate the chat client
        client = nil
        
        // Simulate disconnection completed
        webSocketClient.disconnect_completion?()

        // Assert `ClientError.ClientHasBeenDeallocated` is propagated.
        XCTAssertTrue(error is ClientError.ClientHasBeenDeallocated)
    }

    func test_reloadUserIfNeeded_newUser_propagatesDatabaseFlushError() throws {
        // Create `active` client.
        let client = mockClientWithUserSession()

        // Create `ChatClientUpdater` instance.
        let updater = ChatClientUpdater(client: client)

        // Update database to throw an error when flushed.
        let databaseFlushError = TestError()
        client.mockDatabaseContainer.removeAllData_errorResponse = databaseFlushError

        // Simulate `reloadUserIfNeeded` call and catch the result.
        let error: Error? = try waitFor { completion in
            updater.reloadUserIfNeeded(
                userConnectionProvider: .static(.unique()),
                completion: completion
            )
            
            client.mockWebSocketClient.disconnect_completion!()
        }

        // Assert database error is propagated.
        XCTAssertEqual(error as? TestError, databaseFlushError)
    }

    func test_reloadUserIfNeeded_newUser_propagatesWebSocketClientError_whenAutomaticallyConnects() {
        // Create `active` client.
        let client = ChatClient_Mock(config: .init(apiKeyString: .unique))

        // Create `ChatClientUpdater` instance.
        let updater = ChatClientUpdater(client: client)

        // Simulate `reloadUserIfNeeded` call.
        var reloadUserIfNeededCompletionCalled = false
        var reloadUserIfNeededCompletionError: Error?
        updater.reloadUserIfNeeded(
            userConnectionProvider: .static(.unique())
        ) {
            reloadUserIfNeededCompletionCalled = true
            reloadUserIfNeededCompletionError = $0
        }

        // Simulate error while establishing a connection.
        client.completeConnectionIdWaiters(connectionId: nil)

        // Wait completion is called.
        AssertAsync.willBeTrue(reloadUserIfNeededCompletionCalled)
        // Assert `ClientError.ConnectionNotSuccessfull` is propagated.
        XCTAssertTrue(reloadUserIfNeededCompletionError is ClientError.ConnectionNotSuccessful)
    }

    func test_reloadUserIfNeeded_keepsUpdaterAlive() {
        // Create an active client with user session.
        let client = mockClientWithUserSession()

        // Change the token provider and save the completion.
        var tokenProviderCompletion: ((Result<Token, Error>) -> Void)?

        // Create an updater.
        var updater: ChatClientUpdater? = .init(client: client)
        
        // Simulate `reloadUserIfNeeded` call.
        updater?.reloadUserIfNeeded(
            userConnectionProvider: .closure {
                tokenProviderCompletion = $1
            }
        )

        // Create weak ref and drop a strong one.
        weak var weakUpdater = updater
        updater = nil

        // Assert `reloadUserIfNeeded` keeps updater alive.
        AssertAsync.staysTrue(weakUpdater != nil)

        // Call the completion.
        tokenProviderCompletion!(.success(.anonymous))
        tokenProviderCompletion = nil

        // Assert updater is deallocated.
        AssertAsync.willBeNil(weakUpdater)
    }
    
    func test_reloadUserIfNeeded_firstConnect() throws {
        // Create an active client without a user session.
        let client = ChatClient_Mock(
            config: .init(apiKeyString: .unique),
            workerBuilders: [TestWorker.init]
        )
        // Access the web-socket client to see that connect endpoint is assigned
        // and not rely on lazy init.
        _ = client.webSocketClient
        
        // Declare user id
        let userId: UserId = .unique
        
        // Declare user token
        let token = Token(rawValue: .unique, userId: userId, expiration: nil)
        
        // Create an updater.
        let updater = ChatClientUpdater(client: client)
       
        // Simulate `reloadUserIfNeeded` call.
        var reloadUserIfNeededCompletionCalled = false
        var reloadUserIfNeededCompletionError: Error?
        updater.reloadUserIfNeeded(
            userInfo: .init(id: userId),
            userConnectionProvider: .static(token)
        ) {
            reloadUserIfNeededCompletionCalled = true
            reloadUserIfNeededCompletionError = $0
        }

        // Assert user id is assigned.
        XCTAssertEqual(client.currentUserId, userId)
        // Assert token is assigned.
        XCTAssertEqual(client.currentToken, token)
        // Assert web-socket disconnect is not called
        XCTAssertEqual(
            client.mockWebSocketClient.disconnect_calledCounter,
            0
        )
        // Assert web-socket endpoint for the current user is assigned.
        XCTAssertEqual(
            client.webSocketClient?.connectEndpoint.map(AnyEndpoint.init),
            AnyEndpoint(.webSocketConnect(userInfo: UserInfo(id: userId)))
        )
        // Assert `completeTokenWaiters` is called with the token.
        XCTAssertEqual(client.completeTokenWaiters_token, token)
        // Assert background workers are instantiated
        XCTAssertNotNil(client.testBackgroundWorkerId)
        // Assert store recreation was not triggered since there's no data from prev. user
        XCTAssertFalse(client.mockDatabaseContainer.removeAllData_called)
        // Assert completion hasn't been called yet.
        XCTAssertFalse(reloadUserIfNeededCompletionCalled)

        // Simulate established connection and provide `connectionId` to waiters.
        let connectionId: String = .unique
        client.mockWebSocketClient.simulateConnectionStatus(
            .connected(connectionId: connectionId)
        )
        
        AssertAsync {
            // Assert completion is called.
            Assert.willBeTrue(reloadUserIfNeededCompletionCalled)
            // Assert completion is called without any error.
            Assert.staysTrue(reloadUserIfNeededCompletionError == nil)
            // Assert connection id is set.
            Assert.willBeEqual(client.connectionId, connectionId)
            // Assert connection status is updated.
            Assert.willBeEqual(client.connectionStatus, .connected)
        }
    }

    // MARK: - Private

    private func mockClientWithUserSession(
        isActive: Bool = true,
        token: Token = .unique(userId: .unique)
    ) -> ChatClient_Mock {
        // Create a config.
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isClientInActiveMode = isActive

        // Create a client.
        let client = ChatClient_Mock(config: config)
        client.connectUser(userInfo: .init(id: token.userId), token: token)

        client.currentUserId = token.userId
        client.currentToken = token

        client.connectionId = .unique
        client.connectionStatus = .connected
        client.webSocketClient?.connectEndpoint = .webSocketConnect(
            userInfo: UserInfo(id: token.userId)
        )

        client.createBackgroundWorkers()

        return client
    }
}

// MARK: - Private

private extension ChatClient {
    var testBackgroundWorkerId: Int? {
        backgroundWorkers.first { $0 is MessageSender || $0 is TestWorker }.map { ObjectIdentifier($0).hashValue }
    }
}
