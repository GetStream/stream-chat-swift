//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatClientUpdater_Tests_Tests: StressTestCase {
    typealias ExtraData = NoExtraData

    // MARK: Disconnect

    func test_disconnect_doesNothing_ifClientIsPassive() {
        // Create a passive client with user session.
        let client = mockClientWithUserSession(isActive: false)

        // Create an updater.
        let updater = ChatClientUpdater<ExtraData>(client: client)

        // Simulate `disconnect` call.
        updater.disconnect()

        // Assert `disconnect` was not called on `webSocketClient`.
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 0)
    }

    func test_disconnect_closesTheConnection_ifClientIsActive() {
        // Create an active client with user session.
        let client = mockClientWithUserSession()

        // Create an updater.
        let updater = ChatClientUpdater<ExtraData>(client: client)

        // Simulate `disconnect` call.
        updater.disconnect()

        // Assert `webSocketClient` was disconnected.
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 1)
        // Assert connection id is `nil`.
        XCTAssertNil(client.connectionId)
        // Assert all requests waiting for the connection-id were canceled.
        XCTAssertTrue(client.completeConnectionIdWaiters_called)
        XCTAssertNil(client.completeConnectionIdWaiters_connectionId)
    }

    func test_disconnect_doesNothing_ifThereIsNoConnection() throws {
        // Create an active client with user session.
        let client = mockClientWithUserSession()

        // Create an updater.
        let updater = ChatClientUpdater<ExtraData>(client: client)

        // Simulate `disconnect` call.
        updater.disconnect()

        // Reset disconnect counter.
        client.mockWebSocketClient.disconnect_calledCounter = 0

        // Simulate `disconnect` one more time.
        updater.disconnect()

        // Assert `connect` was not called on `webSocketClient`.
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 0)
    }

    // MARK: Connect

    func test_connect_throwsError_ifClientIsPassive() throws {
        // Create a passive client with user session.
        let client = mockClientWithUserSession(isActive: false)

        // Create an updater.
        let updater = ChatClientUpdater<ExtraData>(client: client)

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
        let updater = ChatClientUpdater<ExtraData>(client: client)

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
        let updater = ChatClientUpdater<ExtraData>(client: client)

        // Disconnect client from web-socket.
        updater.disconnect()

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
            let updater = ChatClientUpdater<ExtraData>(client: client)

            // Disconnect client from web-socket.
            updater.disconnect()

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
                // Simulate web socket `disconnected` state with the specific error.
                client.mockWebSocketClient.simulateConnectionStatus(.disconnected(error: error))
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
            var updater: ChatClientUpdater<ExtraData>? = .init(client: client)

            // Disconnect client from web-socket.
            updater?.disconnect()

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

    func test_reloadUserIfNeeded_happyPaths() throws {
        struct Options {
            let initialToken: Token
            let updatedToken: Token
        }

        // Create current user id.
        let currentUserId: UserId = .unique
        // Create new user id.
        let newUserId: UserId = .unique

        // Create test cases.
        let testCases: [Options] = [
            // Updated token for current user with automatic connect.
            .init(
                initialToken: .unique(userId: currentUserId),
                updatedToken: .unique(userId: currentUserId)
            ),
            // Token for new user with automatic connect.
            .init(
                initialToken: .unique(userId: currentUserId),
                updatedToken: .unique(userId: newUserId)
            )
        ]

        for options in testCases {
            // Create an active client with user session.
            let client = mockClientWithUserSession(token: options.initialToken)

            // Create an updater.
            let updater = ChatClientUpdater<ExtraData>(client: client)

            // Save current background worker ids.
            let oldWorkerIDs = client.testBackgroundWorkerIDs

            // Simulate `reloadUserIfNeeded` call.
            var reloadUserIfNeededCompletionCalled = false
            var reloadUserIfNeededCompletionError: Error?
            updater.reloadUserIfNeeded(
                userConnectionProvider: .static(options.updatedToken)
            ) {
                reloadUserIfNeededCompletionCalled = true
                reloadUserIfNeededCompletionError = $0
            }

            // Assert current user id is valid.
            XCTAssertEqual(client.currentUserId, options.updatedToken.userId)
            // Assert token is valid.
            XCTAssertEqual(client.currentToken, options.updatedToken)
            // Assert web-socket is disconnected.
            XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 1)
            // Assert web-socket endpoint is valid.
            XCTAssertEqual(
                client.webSocketClient?.connectEndpoint.map(AnyEndpoint.init),
                AnyEndpoint(
                    .webSocketConnect(
                        userInfo: UserInfo<NoExtraData>(id: options.updatedToken.userId)
                    )
                )
            )
            // Assert `completeTokenWaiters` was called.
            XCTAssertTrue(client.completeTokenWaiters_called)

            // If it's just the updated token for the current user.
            if options.initialToken.userId == options.updatedToken.userId {
                // Assert `completeTokenWaiters` was called with updated token.
                XCTAssertEqual(client.completeTokenWaiters_token, options.updatedToken)
                // Assert background workers stay the same.
                XCTAssertEqual(client.testBackgroundWorkerIDs, oldWorkerIDs)
                // Assert database is not flushed.
                XCTAssertFalse(client.mockDatabaseContainer.removeAllData_called)
            } else {
                // Assert `completeTokenWaiters` was called with `nil` token which means all
                // pending requests were cancelled.
                XCTAssertNil(client.completeTokenWaiters_token)
                // Assert background workers are recreated since the user has changed.
                XCTAssertNotEqual(client.testBackgroundWorkerIDs, oldWorkerIDs)
                // Assert database was flushed.
                XCTAssertTrue(client.mockDatabaseContainer.removeAllData_called)
            }
            
            // Assert web-socket `connect` is called.
            XCTAssertEqual(client.mockWebSocketClient.connect_calledCounter, 1)
            
            // Assert completion hasn't been called yet.
            XCTAssertFalse(reloadUserIfNeededCompletionCalled)
            
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
    }

    func test_reloadUserIfNeeded_newUser_propagatesClientIsPassiveError() throws {
        // Create config for `passive` client.
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isClientInActiveMode = false

        // Create `passive` client.
        let client = ChatClientMock<ExtraData>(config: config)

        // Create `ChatClientUpdater` instance.
        let updater = ChatClientUpdater<ExtraData>(client: client)

        // Simulate `reloadUserIfNeeded` call and catch the result.
        let error = try waitFor { completion in
            updater.reloadUserIfNeeded(userConnectionProvider: .static(.unique()), completion: completion)
        }

        // Assert `ClientError.ClientIsNotInActiveMode` is propagated.
        XCTAssertTrue(error is ClientError.ClientIsNotInActiveMode)
    }

    func test_reloadUserIfNeeded_newUser_propagatesDatabaseFlushError() throws {
        // Create `active` client.
        let client = ChatClientMock<ExtraData>(config: .init(apiKeyString: .unique))

        // Create `ChatClientUpdater` instance.
        let updater = ChatClientUpdater<ExtraData>(client: client)

        // Update database to throw an error when flushed.
        let databaseFlushError = TestError()
        client.mockDatabaseContainer.removeAllData_errorResponse = databaseFlushError

        // Simulate `reloadUserIfNeeded` call and catch the result.
        let error = try waitFor { completion in
            updater.reloadUserIfNeeded(
                userConnectionProvider: .static(.unique()),
                completion: completion
            )
        }

        // Assert database error is propagated.
        XCTAssertEqual(error as? TestError, databaseFlushError)
    }

    func test_reloadUserIfNeeded_newUser_propagatesWebSocketClientError_whenAutomaticallyConnects() {
        // Create `active` client.
        let client = ChatClientMock<ExtraData>(config: .init(apiKeyString: .unique))

        // Create `ChatClientUpdater` instance.
        let updater = ChatClientUpdater<ExtraData>(client: client)

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
        var updater: ChatClientUpdater<ExtraData>? = .init(client: client)
        
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

    // MARK: - Private

    private func mockClientWithUserSession(
        isActive: Bool = true,
        token: Token = .unique(userId: .unique)
    ) -> ChatClientMock<ExtraData> {
        // Create a config.
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isClientInActiveMode = isActive

        // Create a client.
        let client = ChatClientMock<ExtraData>(
            config: config,
            workerBuilders: [TestWorker.init],
            eventWorkerBuilders: [TestEventWorker.init]
        )
        client.connectUser(userInfo: .init(id: token.userId), token: token)

        client.currentUserId = token.userId
        client.currentToken = token

        client.connectionId = .unique
        client.connectionStatus = .connected
        client.webSocketClient?.connectEndpoint = .webSocketConnect(
            userInfo: UserInfo<NoExtraData>(id: token.userId)
        )

        client.createBackgroundWorkers()

        return client
    }
}

// MARK: - Private

private extension _ChatClient {
    var testBackgroundWorkerIDs: Set<UUID> {
        .init(
            backgroundWorkers.compactMap {
                let testWorker = $0 as? TestWorker
                let eventTestWorker = $0 as? TestEventWorker

                return testWorker?.id ?? eventTestWorker?.id
            }
        )
    }
}
