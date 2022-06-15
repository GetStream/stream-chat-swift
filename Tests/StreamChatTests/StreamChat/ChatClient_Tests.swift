//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatClient_Tests: XCTestCase {
    var userId: UserId!
    private var testEnv: TestEnvironment!
    private var time: VirtualTime!
    
    // A helper providing ChatClientConfig with in-memory DB option
    var inMemoryStorageConfig: ChatClientConfig {
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = true
        config.localStorageFolderURL = .newTemporaryFileURL()
        config.baseURL = BaseURL(urlString: .unique)!
        return config
    }
    
    // Helper for providing config with in-memory DB option and passive (inactive) mode
    lazy var inactiveInMemoryStorageConfig: ChatClientConfig = {
        var config = inMemoryStorageConfig
        config.isClientInActiveMode = false
        return config
    }()
    
    override func setUp() {
        super.setUp()
        userId = .unique
        testEnv = .init()
        time = VirtualTime()
        VirtualTimeTimer.time = time
    }
    
    override func tearDown() {
        testEnv.apiClient?.cleanUp()
        testEnv.clientUpdater?.cleanUp()
        AssertAsync.canBeReleased(&testEnv)
        VirtualTimeTimer.invalidate()
        time = nil
        userId = nil
        super.tearDown()
    }
    
    var workerBuilders: [WorkerBuilder] = [
        NewUserQueryUpdater.init
    ]
    
    var expectedIdentifier: String {
        #if canImport(StreamChatSwiftUI)
        "swiftui"
        #elseif canImport(StreamChatUI)
        "uikit"
        #else
        "swift"
        #endif
    }
    
    // MARK: - Database stack tests
    
    func test_clientDatabaseStackInitialization_whenLocalStorageEnabled_respectsConfigValues() {
        // Prepare a config with the local storage
        let storeFolderURL = URL.newTemporaryDirectoryURL()
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = true
        config.shouldFlushLocalStorageOnStart = true
        config.localStorageFolderURL = storeFolderURL
        
        config.localCaching.chatChannel.lastActiveMembersLimit = .unique
        config.localCaching.chatChannel.lastActiveWatchersLimit = .unique

        config.deletedMessagesVisibility = .alwaysVisible
        config.shouldShowShadowedMessages = .random()

        var usedDatabaseKind: DatabaseContainer.Kind?
        var shouldFlushDBOnStart: Bool?
        var shouldResetEphemeralValues: Bool?
        var localCachingSettings: ChatClientConfig.LocalCaching?
        var deleteMessagesVisibility: ChatClientConfig.DeletedMessageVisibility?
        var shouldShowShadowedMessages: Bool?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = ChatClientUpdater_Mock.init
        env
            .databaseContainerBuilder =
            { kind, shouldFlushOnStart, shouldResetEphemeralValuesOnStart, cachingSettings, messageVisibility, showShadowedMessages in
                usedDatabaseKind = kind
                shouldFlushDBOnStart = shouldFlushOnStart
                shouldResetEphemeralValues = shouldResetEphemeralValuesOnStart
                localCachingSettings = cachingSettings
                deleteMessagesVisibility = messageVisibility
                shouldShowShadowedMessages = showShadowedMessages
                return DatabaseContainer_Spy()
            }
        
        // Create a `Client` and assert that a DB file is created on the provided URL + APIKey path
        _ = ChatClient(
            config: config,
            environment: env
        )

        XCTAssertEqual(
            usedDatabaseKind,
            .onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString))
        )
        XCTAssertEqual(shouldFlushDBOnStart, config.shouldFlushLocalStorageOnStart)
        XCTAssertEqual(shouldResetEphemeralValues, config.isClientInActiveMode)
        XCTAssertEqual(localCachingSettings, config.localCaching)
        XCTAssertEqual(deleteMessagesVisibility, config.deletedMessagesVisibility)
        XCTAssertEqual(shouldShowShadowedMessages, config.shouldShowShadowedMessages)
    }
    
    func test_clientDatabaseStackInitialization_whenLocalStorageDisabled() {
        // Prepare a config with the in-memory storage
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
        
        var usedDatabaseKind: DatabaseContainer.Kind?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = ChatClientUpdater_Mock.init
        env.databaseContainerBuilder = { kind, _, _, _, _, _ in
            usedDatabaseKind = kind
            return DatabaseContainer_Spy()
        }
        
        // Create a `Client` and assert the correct DB kind is used
        _ = ChatClient(
            config: config,
            environment: env
        )
        
        XCTAssertEqual(usedDatabaseKind, .inMemory)
    }
    
    /// When the initialization of a local DB fails for some reason (i.e. incorrect URL),
    /// use a DB in the in-memory configuration
    func test_clientDatabaseStackInitialization_useInMemoryWhenOnDiskFails() {
        // Prepare a config with nil local storage
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = true
        config.localStorageFolderURL = nil
        
        var usedDatabaseKinds: [DatabaseContainer.Kind] = []

        // Create env object and store all `kinds it's called with.
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = ChatClientUpdater_Mock.init
        env.databaseContainerBuilder = { kind, _, _, _, _, _ in
            usedDatabaseKinds.append(kind)
            return DatabaseContainer_Spy()
        }
        
        // Create a chat client and assert `Client` tries to initialize the local DB, and when it fails, it falls back
        // to the in-memory option.
        _ = ChatClient(
            config: config,
            environment: env
        )
        
        XCTAssertEqual(
            usedDatabaseKinds,
            [.inMemory]
        )
    }
    
    // MARK: - WebSocketClient tests
    
    func test_webSocketClientConfiguration() throws {
        // Use in-memory store
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        
        client.connectAnonymousUser()

        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Assert the init parameters are correct
        let webSocket = testEnv.webSocketClient
        assertMandatoryHeaderFields(webSocket?.init_sessionConfiguration)
        XCTAssertEqual(webSocket?.init_sessionConfiguration.waitsForConnectivity, false)
        XCTAssert(webSocket?.init_requestEncoder is RequestEncoder_Spy)
        XCTAssert(webSocket?.init_eventNotificationCenter.database === client.databaseContainer)
        XCTAssertNotNil(webSocket?.init_eventDecoder)
        
        // EventDataProcessorMiddleware must be always first
        XCTAssert(webSocket?.init_eventNotificationCenter.middlewares[0] is EventDataProcessorMiddleware)
        
        // Assert Client sets itself as delegate for the request encoder
        XCTAssert(webSocket?.init_requestEncoder.connectionDetailsProviderDelegate === client)
    }
    
    func test_webSocketClient_hasAllMandatoryMiddlewares() throws {
        // Use in-memory store
        // Create a new chat client, which in turn creates a webSocketClient
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )

        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Assert that mandatory middlewares exists
        let middlewares = try XCTUnwrap(testEnv.webSocketClient?.init_eventNotificationCenter.middlewares)
        
        // Assert `EventDataProcessorMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is EventDataProcessorMiddleware }))
        // Assert `TypingStartCleanupMiddleware` exists
        let typingStartCleanupMiddlewareIndex = middlewares.firstIndex { $0 is TypingStartCleanupMiddleware }
        XCTAssertNotNil(typingStartCleanupMiddlewareIndex)
        // Assert `ChannelReadUpdaterMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is ChannelReadUpdaterMiddleware }))
        // Assert `ChannelMemberTypingStateUpdaterMiddleware` exists
        let typingStateUpdaterMiddlewareIndex = middlewares
            .firstIndex { $0 is UserTypingStateUpdaterMiddleware }
        XCTAssertNotNil(typingStateUpdaterMiddlewareIndex)
        // Assert `ChannelMemberTypingStateUpdaterMiddleware` goes after `TypingStartCleanupMiddleware`
        XCTAssertTrue(typingStateUpdaterMiddlewareIndex! > typingStartCleanupMiddlewareIndex!)
        // Assert `ChannelTruncatedEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is ChannelTruncatedEventMiddleware }))
        // Assert `MemberEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is MemberEventMiddleware }))
        // Assert `UserChannelBanEventsMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is UserChannelBanEventsMiddleware }))
        // Assert `UserWatchingEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is UserWatchingEventMiddleware }))
        // Assert `ChannelVisibilityEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is ChannelVisibilityEventMiddleware }))
        // Assert `EventDTOConverterMiddleware` is the last one
        XCTAssertTrue(middlewares.last is EventDTOConverterMiddleware)
    }
    
    func test_connectionStatus_isExposed() {
        let config = inMemoryStorageConfig

        let client = ChatClient(
            config: config
        )
        
        client.webSocketClient?.simulateConnectionStatus(.connecting)
        // Assert connection status is `.initialized`
        XCTAssertEqual(client.connectionStatus, .connecting)

        // Simulate established web-socket connection.
        client.webSocketClient?.simulateConnectionStatus(.connected(connectionId: .unique))
        // Assert the WSConnectionState is exposed as ChatClientConnectionStatus
        XCTAssertEqual(client.connectionStatus, .connected)
        
        // Simulate web-socket disconnection.
        let stopError = WebSocketEngineError(
            reason: .unique,
            code: WebSocketEngineError.stopErrorCode,
            engineError: nil
        )
        let error = ClientError(with: stopError)
        client.webSocketClient?.simulateConnectionStatus(.disconnected(source: .serverInitiated(error: error)))

        // Assert the WSConnectionState is exposed as ChatClientConnectionStatus
        XCTAssertEqual(client.connectionStatus, .disconnected(error: error))
    }
    
    // MARK: - ConnectionDetailsProvider tests
    
    func test_clientProvidesConnectionId() throws {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )

        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Set a connection Id waiter and assert it's `nil`
        var connectionResult: Result<ConnectionId, Error>?
        client.provideConnectionId {
            connectionResult = $0
        }
        XCTAssertNil(connectionResult)
        
        // Simulate WebSocketConnection change
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        
        AssertAsync.staysTrue(connectionResult == nil)
        
        // Simulate WebSocket connected and connection id is provided
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        AssertAsync.willBeEqual(connectionResult?.value, connectionId)
        XCTAssertEqual(try waitFor { client.provideConnectionId(completion: $0) }.value, connectionId)
        
        // Simulate WebSocketConnection disconnecting and assert connectionId is reset
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        
        connectionResult = nil
        client.provideConnectionId {
            connectionResult = $0
        }
        AssertAsync.staysTrue(connectionResult == nil)
    }
    
    func test_client_failsConnectionIdWaiters_whenWebSocketIsDisconnected() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        
        client.connectAnonymousUser()

        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Set a connection Id waiter and set `providedConnectionId` to a non-nil value
        var providedConnectionIdResult: Result<ConnectionId, Error>? = .success(.unique)
        client.provideConnectionId {
            providedConnectionIdResult = $0
        }
        XCTAssertNotNil(providedConnectionIdResult)
        
        // Simulate WebSocketConnection change to "disconnected"
        let error = ClientError(with: TestError())
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(
                testEnv.webSocketClient!,
                didUpdateConnectionState: .disconnected(source: .serverInitiated(error: error))
            )
        
        // Assert the provided connection id is `nil`
        XCTAssertNil(providedConnectionIdResult?.value)
        
        // Simulate WebSocketConnection change to "connected" and assert `providedConnectionId` is still `nil`
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: .unique))

        XCTAssertNil(providedConnectionIdResult?.value)
    }
    
    func test_webSocketIsDisconnected_becauseTokenExpired_newTokenIsExpiredToo() throws {
        // GIVEN
        let client = makeConnectedChatClient(token: .unique(userId: userId))
        
        // WHEN
        let error = ClientError(with: ErrorPayload(code: 40, message: "", statusCode: 200))
        client.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .serverInitiated(error: error)))

        // THEN
        XCTAssertNil(client.connectionId)
        XCTAssertEqual(client.mockChatClientUpdater.mock_handleExpiredTokenError.calls.count, 1)
        XCTAssertEqual(client.mockChatClientUpdater.mock_handleExpiredTokenError.calls.first?.0, error)
    }
    
    func test_clientProvidesConnectionId_afterUnlockingResources() {
        // IMPORTANT: This test hangs (freezes) if there's simulatenous
        // access to `connectionId`, so freeze = failure for this test
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Set a connection Id waiter and set `providedConnectionId` to nil value
        var providedConnectionIdResult: Result<ConnectionId, Error>?
        client.provideConnectionId { _ in
            // Set another connectionId waiter inside the first one
            // This is to simulate the case where 2 entities call this func
            // Like, calling `synchronize` in a delegate callback
            client.provideConnectionId {
                providedConnectionIdResult = $0
            }
        }
        XCTAssertNil(providedConnectionIdResult)
        
        // Simulate providing connection id
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        // Assert that our waiter received the new connectionId
        AssertAsync.willBeEqual(providedConnectionIdResult?.value, connectionId)
    }

    func test_invalidateTokenWaiterRemovesBlockFromWaiter() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )

        let waiterToken = client.provideToken { _ in
            XCTFail("Should not reach here because the block should be removed when invalidating")
        }
        
        client.invalidateTokenWaiter(waiterToken)
        
        // We simulate token waiters completion to make sure the previously invalidated block is not executed
        client.tokenHandler.cancelRefreshFlow(with: TestError())
    }

    func test_invalidateConnectionIdWaiterRemovesBlockFromWaiter() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )

        let waiterToken = client.provideConnectionId { [weak client] _ in
            // We call the block when it deinits, and this check is not important for us then
            guard client != nil else { return }
            XCTFail("Should not reach here because the block should be removed when invalidating")
        }

        XCTAssertEqual(client.connectionIdWaiters.count, 1)

        client.invalidateConnectionIdWaiter(waiterToken)

        XCTAssertEqual(client.connectionIdWaiters.count, 0)

        // We simulate connection id waiters completion to make sure the previously invalidated block is not executed
        client.completeConnectionIdWaiters(result: .failure(TestError()))
    }
    
    // MARK: - APIClient tests
    
    func test_apiClientConfiguration() throws {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )

        // Simulate access to `apiClient` so it is initialized
        _ = client.apiClient
        
        assertMandatoryHeaderFields(testEnv.apiClient?.init_sessionConfiguration)
        XCTAssert(testEnv.apiClient?.init_requestDecoder is RequestDecoder_Spy)
        XCTAssert(testEnv.apiClient?.init_requestEncoder is RequestEncoder_Spy)
    }
    
    func test_disconnect_flushesRequestsQueue() {
        // Create a chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        
        // Disconnect chat client
        client.disconnect()
        
        // Assert client is not recreated
        XCTAssertTrue(testEnv.apiClient! === client.apiClient)
        // Assert `disconnect` on updater is triggered
        XCTAssertTrue(testEnv.clientUpdater!.disconnect_called)
        // Assert source is user initiated
        XCTAssertEqual(testEnv.clientUpdater!.disconnect_source, .userInitiated)
    }
    
    func test_disconnect_whenCurrentUserExists_resetsConnectionProvider() {
        // GIVEN
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        client.currentUserId = .unique
        
        // WHEN
        client.disconnect()
        
        // THEN
        switch client.tokenHandler.connectionProvider {
        case let .notInitiated(userId):
            XCTAssertEqual(userId, client.currentUserId)
        default:
            XCTFail()
        }
    }
    
    func test_disconnect_whenCurrentUserDoesNotExist_resetsConnectionProvider() {
        // GIVEN
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        
        // WHEN
        client.disconnect()
        
        // THEN
        switch client.tokenHandler.connectionProvider {
        case .noCurrentUser:
            break
        default:
            XCTFail()
        }
    }
    
    func test_whenAPIClientTriggersTokenRefresher_clientUpdaterIsTriggeredAndCompletionIsCalledWithResult() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient_Mock(config: inMemoryStorageConfig)
            
            let serverError = ClientError("some message")
            let tokenRefresherCompletionCalled = expectation(description: "tokenRefresher completion called")
            var tokenRefresherCompletionError: Error?
            client.mockAPIClient.init_tokenRefresher(serverError) { error in
                tokenRefresherCompletionError = error
                tokenRefresherCompletionCalled.fulfill()
            }
            
            XCTAssertEqual(client.mockChatClientUpdater.mock_handleExpiredTokenError.calls.count, 1)
            XCTAssertEqual(client.mockChatClientUpdater.mock_handleExpiredTokenError.calls.first?.0, serverError)
            
            // WHEN
            client.mockChatClientUpdater.mock_handleExpiredTokenError.calls.first?.1?(error)
            
            // THEN
            wait(for: [tokenRefresherCompletionCalled], timeout: defaultTimeout)
            XCTAssertEqual(tokenRefresherCompletionError as? TestError, error)
        }
    }
    
    func test_whenAPIClientTriggersTokenRefresherAndClientIsDeallocated_errorIsReturned() throws {
        // GIVEN
        var client: ChatClient_Mock? = ChatClient_Mock(config: inMemoryStorageConfig)
        let tokenRefresher = try XCTUnwrap(client?.mockAPIClient.init_tokenRefresher)
        
        // WHEN
        client = nil
        
        let serverError = ClientError("some message")
        let tokenRefresherCompletionCalled = expectation(description: "tokenRefresher completion called")
        var tokenRefresherCompletionError: Error?
        tokenRefresher(serverError) { error in
            tokenRefresherCompletionError = error
            tokenRefresherCompletionCalled.fulfill()
        }
        
        // THEN
        wait(for: [tokenRefresherCompletionCalled], timeout: defaultTimeout)
        XCTAssertTrue(tokenRefresherCompletionError is ClientError.ClientHasBeenDeallocated)
    }
    
    // MARK: - Background workers tests
    
    func test_productionClientIsInitalizedWithAllMandatoryBackgroundWorkers() {
        let config = inMemoryStorageConfig

        // Create a new chat client
        var env = ChatClient.Environment()
        env.webSocketClientBuilder = {
            WebSocketClient_Mock(
                sessionConfiguration: $0,
                requestEncoder: $1,
                eventDecoder: $2,
                eventNotificationCenter: $3
            )
        }
        var client: ChatClient! = ChatClient(config: config, environment: env)
        client.connectAnonymousUser { _ in }
        
        wait(for: [client.mockWebSocketClient.connect_expectation], timeout: defaultTimeout)
        
        // Check all the mandatory background workers are initialized
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageSender })
        XCTAssert(client.backgroundWorkers.contains { $0 is NewUserQueryUpdater })
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageEditor })
        XCTAssert(client.backgroundWorkers.contains { $0 is AttachmentUploader })
        XCTAssertNotNil(client.connectionRecoveryHandler)
        
        AssertAsync.canBeReleased(&client)
    }
    
    func test_backgroundWorkersConfiguration() {
        // Set up mocks for APIClient, WSClient and Database
        let config = ChatClientConfig(apiKey: .init(.unique))
        
        // Create a Client instance and check the workers are initialized properly
        let client = ChatClient(
            config: config,
            environment: testEnv.environment
        )

        // Simulate `createBackgroundWorkers` so workers are created.
        client.createBackgroundWorkers()

        XCTAssert(client.backgroundWorkers.first is MessageSender)

        XCTAssertNotNil(client.connectionRecoveryHandler)
    }
    
    // MARK: - Init

    func test_currentUserIsFetched_whenInitIsFinished_noMatterOnWhichThread() throws {
        // Create current user id.
        let currentUserId: UserId = .unique
        // Create a config with on-disk storage.
        let config = ChatClientConfig(apiKeyString: .unique)
        // Create an active client to save the current user to the database.
        var chatClient: ChatClient! = ChatClient(config: config)
        
        // Create current user in the database.
        try chatClient.databaseContainer.createCurrentUser(id: currentUserId)

        AssertAsync.canBeReleased(&chatClient)
        
        // Take main then background queue.
        for queue in [DispatchQueue.main, DispatchQueue.global()] {
            let error: Error? = try waitFor { completion in
                // Dispatch creating a chat-client to specific queue.
                queue.async {
                    // Create a `ChatClient` instance with the same config
                    // to access the storage with exited current user.
                    let chatClient = ChatClient(config: config)

                    let expectedWebSocketEndpoint = AnyEndpoint(
                        .webSocketConnect(userInfo: UserInfo(id: currentUserId))
                    )

                    // 1. Check `currentUserId` is fetched synchronously
                    // 2. `webSocket` has correct connect endpoint
                    if chatClient.currentUserId == currentUserId,
                       chatClient.webSocketClient?.connectEndpoint.map(AnyEndpoint.init) == expectedWebSocketEndpoint {
                        completion(nil)
                    } else {
                        completion(TestError())
                    }
                }
            }

            XCTAssertNil(error)
        }
    }
    
    func test_userConnectionProvider_whenUserExists_hasCorrectInitialValue() throws {
        // GIVEN
        let currentUserId: UserId = .unique
        let config = ChatClientConfig(apiKeyString: .unique)
        
        try ChatClient(config: config)
            .databaseContainer
            .createCurrentUser(id: currentUserId)
        
        // WHEN
        let client = ChatClient(config: config)
        
        // THEN
        switch client.tokenHandler.connectionProvider {
        case let .notInitiated(userId):
            XCTAssertEqual(userId, currentUserId)
        case .noCurrentUser, .initiated:
            XCTFail()
        }
    }
    
    func test_userConnectionProvider_whenUserDoesNotExist_hasCorrectInitialValue() throws {
        // WHEN
        let client = ChatClient(config: .init(apiKeyString: .unique))
        
        // THEN
        switch client.tokenHandler.connectionProvider {
        case .noCurrentUser:
            break
        default:
            XCTFail()
        }
    }
    
    // MARK: - Connect
    
    func test_connectUserWithTokenProvider_callsUpdaterAndPropagatesResultToCompletion() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient_Mock(config: inMemoryStorageConfig)
            
            let token = Token.unique()
            let tokenProvider: TokenProvider = { $0(.success(token)) }
            let connectCompletionCalled = expectation(description: "connectUser completion called")
            var connectCompletionError: Error?
            client.connectUser(userInfo: .init(id: token.userId), tokenProvider: tokenProvider) {
                connectCompletionError = $0
                connectCompletionCalled.fulfill()
            }
            
            XCTAssertEqual(client.mockChatClientUpdater.reloadUserIfNeeded_callsCount, 1)
            XCTAssertEqual(
                client.mockTokenHandler.connectionProvider,
                .initiated(userId: token.userId, tokenProvider: tokenProvider)
            )

            // WHEN
            client.mockChatClientUpdater.reloadUserIfNeeded_completion!(error)
            
            // THEN
            wait(for: [connectCompletionCalled], timeout: defaultTimeout)
            XCTAssertEqual(connectCompletionError as? TestError, error)
        }
    }
    
    func test_connectUserWithToken_callsUpdaterAndPropagatesResultToCompletion() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient_Mock(config: inMemoryStorageConfig)
            
            let token = Token.unique()
            let connectCompletionCalled = expectation(description: "connectUser completion called")
            var connectCompletionError: Error?
            client.connectUser(userInfo: .init(id: token.userId), token: token) {
                connectCompletionError = $0
                connectCompletionCalled.fulfill()
            }
            
            XCTAssertEqual(client.mockChatClientUpdater.reloadUserIfNeeded_callsCount, 1)
            XCTAssertEqual(
                client.mockTokenHandler.connectionProvider,
                .static(token)
            )

            // WHEN
            client.mockChatClientUpdater.reloadUserIfNeeded_completion!(error)
            
            // THEN
            wait(for: [connectCompletionCalled], timeout: defaultTimeout)
            XCTAssertEqual(connectCompletionError as? TestError, error)
        }
    }
    
    func test_connectGuestUser_callsUpdaterAndPropagatesResultToCompletion() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient_Mock(config: inMemoryStorageConfig)
            
            let userInfo = UserInfo(
                id: .unique,
                name: .unique,
                imageURL: .localYodaImage,
                extraData: [:]
            )
            let connectCompletionCalled = expectation(description: "connectUser completion called")
            var connectCompletionError: Error?
            client.connectGuestUser(userInfo: userInfo) {
                connectCompletionError = $0
                connectCompletionCalled.fulfill()
            }
            
            XCTAssertEqual(client.mockChatClientUpdater.reloadUserIfNeeded_callsCount, 1)
            XCTAssertEqual(
                client.mockTokenHandler.connectionProvider,
                .guest(client: client, userId: userInfo.id)
            )

            // WHEN
            client.mockChatClientUpdater.reloadUserIfNeeded_completion!(error)
            
            // THEN
            wait(for: [connectCompletionCalled], timeout: defaultTimeout)
            XCTAssertEqual(connectCompletionError as? TestError, error)
        }
    }
    
    func test_connectAnonymousUser_callsUpdaterAndPropagatesResultToCompletion() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient_Mock(config: inMemoryStorageConfig)
            
            let connectCompletionCalled = expectation(description: "connectUser completion called")
            var connectCompletionError: Error?
            client.connectAnonymousUser {
                connectCompletionError = $0
                connectCompletionCalled.fulfill()
            }
            
            var providedToken: Token?
            client.mockTokenHandler.connectionProvider.fetchToken { providedToken = try? $0.get() }
            XCTAssertEqual(providedToken?.userId.isAnonymousUser, true)
            XCTAssertEqual(client.mockChatClientUpdater.reloadUserIfNeeded_callsCount, 1)
            
            // WHEN
            client.mockChatClientUpdater.reloadUserIfNeeded_completion!(error)
            
            // THEN
            wait(for: [connectCompletionCalled], timeout: defaultTimeout)
            XCTAssertEqual(connectCompletionError as? TestError, error)
        }
    }
    
    // MARK: - Set token
    
    func test_setToken_callsUpdaterAndPropagatesResultToCompletion() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient_Mock(config: inMemoryStorageConfig)
            
            let token = Token.unique()
            let setTokenCompletionCalled = expectation(description: "connectUser completion called")
            var setTokenCompletionError: Error?
            client.setToken(token: token) {
                setTokenCompletionError = $0
                setTokenCompletionCalled.fulfill()
            }
            
            XCTAssertEqual(client.mockTokenHandler.mock_setToken.calls.count, 1)
            XCTAssertEqual(client.mockTokenHandler.mock_setToken.calls.first?.0, token)
            
            // WHEN
            client.mockTokenHandler.mock_setToken.calls.first?.1?(error)
            
            // THEN
            wait(for: [setTokenCompletionCalled], timeout: defaultTimeout)
            XCTAssertEqual(setTokenCompletionError as? TestError, error)
        }
    }

    // MARK: - Passive (not active) Client tests
    
    func test_passiveClient_doesNotHaveWorkers() {
        // Create Client with inactive flag set
        let client = ChatClient(config: inactiveInMemoryStorageConfig)

        // Simulate `createBackgroundWorkers`.
        client.createBackgroundWorkers()
        
        // Assert that no background worker is initialized
        XCTAssert(client.backgroundWorkers.isEmpty)
    }
    
    func test_passiveClient_doesNotHaveWSClient() {
        // Create Client with inactive flag set
        let client = ChatClient(config: inactiveInMemoryStorageConfig)
        
        // Assert the wsClient is not initialized
        XCTAssertNil(client.webSocketClient)
    }
    
    func test_passiveClient_provideConnectionId_returnsImmediately() {
        // Create Client with inactive flag set
        let client = ChatClient(config: inactiveInMemoryStorageConfig)
        
        // Set a connection Id waiter
        var providedConnectionIdResult: Result<ConnectionId, Error>? = .success(.unique)
        var connectionIdCallbackCalled = false
        client.provideConnectionId {
            providedConnectionIdResult = $0
            connectionIdCallbackCalled = true
        }
        
        AssertAsync.willBeTrue(connectionIdCallbackCalled)
        // Assert that `nil` id is provided by waiter
        XCTAssertTrue(providedConnectionIdResult?.error is ClientError.ClientIsNotInActiveMode)
    }
    
    func test_sessionHeaders_xStreamClient_correctValue() {
        // Given
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        
        // When
        client.connectAnonymousUser()
        
        // Then
        guard let sessionHeaders = client.apiClient.session.configuration.httpAdditionalHeaders,
              let streamHeader = sessionHeaders["X-Stream-Client"] as? String else {
            return XCTFail("X-Stream-Client key should exist as a HTTP additional header.")
        }
        
        XCTAssertEqual(streamHeader, SystemEnvironment.xStreamClientHeader)
    }
    
    // MARK: - Private
    
    private func makeConnectedChatClient(token: Token, tokenProvider: TokenProvider? = nil) -> ChatClient_Mock {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false

        let client = ChatClient_Mock(config: config)
        client.currentUserId = userId
        client.mockTokenHandler.currentToken = token
        client.mockTokenHandler.connectionProvider = .initiated(
            userId: token.userId,
            tokenProvider: tokenProvider ?? { $0(.success(token)) }
        )
        client.webSocketClient?.simulateConnectionStatus(.connected(connectionId: .unique))
        return client
    }
}

final class TestWorker: Worker {
    let id = UUID()
    
    var init_database: DatabaseContainer?
    var init_apiClient: APIClient?
    
    override init(database: DatabaseContainer, apiClient: APIClient) {
        init_database = database
        init_apiClient = apiClient
        
        super.init(database: database, apiClient: apiClient)
    }
}

/// A helper class which provides mock environment for Client.
private class TestEnvironment {
    @Atomic var apiClient: APIClient_Spy?
    @Atomic var webSocketClient: WebSocketClient_Mock?
    @Atomic var databaseContainer: DatabaseContainer_Spy?
    
    @Atomic var requestEncoder: RequestEncoder_Spy?
    @Atomic var requestDecoder: RequestDecoder_Spy?
    
    @Atomic var eventDecoder: EventDecoder?
    
    @Atomic var notificationCenter: EventNotificationCenter?

    @Atomic var clientUpdater: ChatClientUpdater_Mock?
    
    @Atomic var backgroundTaskScheduler: BackgroundTaskScheduler_Mock?
    
    @Atomic var internetConnection: InternetConnection_Mock?
    var monitor: InternetConnectionMonitor_Mock?

    lazy var environment: ChatClient.Environment = { [unowned self] in
        .init(
            apiClientBuilder: {
                self.apiClient = APIClient_Spy(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    requestDecoder: $2,
                    CDNClient: $3,
                    tokenRefresher: $4,
                    queueOfflineRequest: $5
                )
                return self.apiClient!
            },
            webSocketClientBuilder: {
                self.webSocketClient = WebSocketClient_Mock(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    eventDecoder: $2,
                    eventNotificationCenter: $3
                )
                return self.webSocketClient!
            },
            databaseContainerBuilder: {
                self.databaseContainer = DatabaseContainer_Spy(
                    kind: $0,
                    shouldFlushOnStart: $1,
                    shouldResetEphemeralValuesOnStart: $2,
                    localCachingSettings: $3,
                    deletedMessagesVisibility: $4,
                    shouldShowShadowedMessages: $5
                )
                return self.databaseContainer!
            },
            requestEncoderBuilder: {
                if let encoder = self.requestEncoder {
                    return encoder
                }
                self.requestEncoder = RequestEncoder_Spy(baseURL: $0, apiKey: $1)
                return self.requestEncoder!
            },
            requestDecoderBuilder: {
                self.requestDecoder = RequestDecoder_Spy()
                return self.requestDecoder!
            },
            eventDecoderBuilder: {
                self.eventDecoder = EventDecoder()
                return self.eventDecoder!
            },
            notificationCenterBuilder: {
                self.notificationCenter = EventNotificationCenter_Mock(database: $0)
                return self.notificationCenter!
            },
            internetConnection: {
                self.internetConnection = InternetConnection_Mock(
                    monitor: $1 as! InternetConnectionMonitor_Mock,
                    notificationCenter: $0
                )
                return self.internetConnection!
            },
            monitor: InternetConnectionMonitor_Mock(),
            clientUpdaterBuilder: {
                self.clientUpdater = ChatClientUpdater_Mock(client: $0)
                return self.clientUpdater!
            },
            backgroundTaskSchedulerBuilder: {
                self.backgroundTaskScheduler = BackgroundTaskScheduler_Mock()
                return self.backgroundTaskScheduler!
            }
        )
    }()
}

extension ChatClient_Tests {
    /// Asserts that URLSessionConfiguration contains all require header fields
    private func assertMandatoryHeaderFields(
        _ config: URLSessionConfiguration?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let config = config else {
            XCTFail("Config is `nil`", file: file, line: line)
            return
        }
        
        let headers = config.httpAdditionalHeaders as? [String: String] ?? [:]
        XCTAssertEqual(
            headers["X-Stream-Client"],
            SystemEnvironment.xStreamClientHeader
        )
    }
}

private struct Queue<Element> {
    @Atomic private var storage = [Element]()
    mutating func push(_ element: Element) {
        _storage.mutate { $0.append(element) }
    }
    
    mutating func pop() -> Element? {
        var first: Element?
        _storage.mutate { storage in
            first = storage.first
            storage = Array(storage.dropFirst())
        }
        return first
    }
}

private extension ChatClientConfig {
    init() {
        self = .init(apiKey: APIKey(.unique))
    }
}
