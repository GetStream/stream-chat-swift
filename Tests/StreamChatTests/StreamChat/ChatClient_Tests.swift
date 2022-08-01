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

        // Create an environment.
        var clientUpdater: ChatClientUpdater?
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = {
            if let updater = clientUpdater {
                return updater
            } else {
                let updater = ChatClientUpdater(client: $0)
                clientUpdater = updater
                return updater
            }
        }

        // Create a new chat client.
        var initCompletionCalled = false
        let client = ChatClient(
            config: config,
            environment: env
        )
        
        client.connectAnonymousUser { error in
            XCTAssertNil(error)
            initCompletionCalled = true
        }

        XCTAssertFalse(initCompletionCalled)
        // Assert connection status is `.initialized`
        XCTAssertEqual(client.connectionStatus, .connecting)

        // Simulate `connect` call and catch the completion.
        var connectCompletionCalled = false
        clientUpdater?.connect { error in
            XCTAssertNil(error)
            connectCompletionCalled = true
        }

        // Assert `connect` completion hasn't been called yet.
        XCTAssertFalse(connectCompletionCalled)

        // Simulate established web-socket connection.
        client.webSocketClient?.simulateConnectionStatus(.connected(connectionId: .unique))
        // Assert the WSConnectionState is exposed as ChatClientConnectionStatus
        XCTAssertEqual(client.connectionStatus, .connected)

        // Assert `connect` completion is called.
        XCTAssertTrue(connectCompletionCalled)

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
        var providedConnectionId: ConnectionId?
        client.provideConnectionId {
            providedConnectionId = $0
        }
        XCTAssertNil(providedConnectionId)
        
        // Simulate WebSocketConnection change
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        
        AssertAsync.staysTrue(providedConnectionId == nil)
        
        // Simulate WebSocket connected and connection id is provided
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        AssertAsync.willBeEqual(providedConnectionId, connectionId)
        XCTAssertEqual(try waitFor { client.provideConnectionId(completion: $0) }, connectionId)
        
        // Simulate WebSocketConnection disconnecting and assert connectionId is reset
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        
        providedConnectionId = nil
        client.provideConnectionId {
            providedConnectionId = $0
        }
        AssertAsync.staysTrue(providedConnectionId == nil)
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
        var providedConnectionId: ConnectionId? = .unique
        client.provideConnectionId {
            providedConnectionId = $0
        }
        XCTAssertNotNil(providedConnectionId)
        
        // Simulate WebSocketConnection change to "disconnected"
        let error = ClientError(with: TestError())
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(
                testEnv.webSocketClient!,
                didUpdateConnectionState: .disconnected(source: .serverInitiated(error: error))
            )
        
        // Assert the provided connection id is `nil`
        XCTAssertNil(providedConnectionId)
        
        // Simulate WebSocketConnection change to "connected" and assert `providedConnectionId` is still `nil`
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: .unique))

        XCTAssertNil(providedConnectionId)
    }
    
    func test_webSocketIsDisconnected_becauseTokenExpired_newTokenIsExpiredToo() throws {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        
        let userId: UserId = .unique
        client.connectUser(userInfo: .init(id: userId), tokenProvider: { $0(.success(.unique(userId: userId))) })

        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Simulate .connected state to obtain connection id
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        XCTAssertEqual(client.connectionId, connectionId)
        
        // Was called on ChatClient init
        XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 1)

        // Simulate WebSocketConnection change to "disconnected"
        let error = ClientError(with: ErrorPayload(code: 40, message: "", statusCode: 200, details: []))
        testEnv.webSocketClient?
            .connectionStateDelegate?
            .webSocketClient(
                testEnv.webSocketClient!,
                didUpdateConnectionState: .disconnected(source: .serverInitiated(error: error))
            )
        
        time.run(numberOfSeconds: 0.6)
        // Was called one more time on receiving token expired error
        AssertAsync.willBeEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 2)
        
        // Token is expired again
        testEnv.webSocketClient?
            .connectionStateDelegate?
            .webSocketClient(
                testEnv.webSocketClient!,
                didUpdateConnectionState: .disconnected(source: .serverInitiated(error: error))
            )
        
        // Does not call secondary token refresh right away
        XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 2)
        
        // Does not call secondary token refresh when not enough time has passed
        time.run(numberOfSeconds: 0.1)
        XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 2)
        
        // Calls secondary token refresh when enough time has passed
        time.run(numberOfSeconds: 3)
        AssertAsync.willBeEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 3)

        // We set connectionId to nil after token expiration disconnect
        XCTAssertNil(client.connectionId)
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
        var providedConnectionId: ConnectionId?
        client.provideConnectionId { _ in
            // Set another connectionId waiter inside the first one
            // This is to simulate the case where 2 entities call this func
            // Like, calling `synchronize` in a delegate callback
            client.provideConnectionId {
                providedConnectionId = $0
            }
        }
        XCTAssertNil(providedConnectionId)
        
        // Simulate providing connection id
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connecting)
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        // Assert that our waiter received the new connectionId
        AssertAsync.willBeEqual(providedConnectionId, connectionId)
    }

    func test_invalidateTokenWaiterRemovesBlockFromWaiter() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )

        client.provideToken { [weak client] _ in
            // We call the block when it deinits, and this check is not important for us then
            guard client != nil else { return }
            XCTFail("Should not reach here because the block should be removed when invalidating")
        }

        XCTAssertEqual(client.tokenWaiters.count, 1)

        guard let waiterToken = client.tokenWaiters.first?.key else {
            XCTFail("Should have a token")
            return
        }

        client.invalidateTokenWaiter(waiterToken)

        XCTAssertEqual(client.tokenWaiters.count, 0)

        // We simulate token waiters completion to make sure the previously invalidated block is not executed
        client.completeTokenWaiters(token: nil)
    }

    func test_invalidateConnectionIdWaiterRemovesBlockFromWaiter() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )

        client.provideConnectionId { [weak client] _ in
            // We call the block when it deinits, and this check is not important for us then
            guard client != nil else { return }
            XCTFail("Should not reach here because the block should be removed when invalidating")
        }

        XCTAssertEqual(client.connectionIdWaiters.count, 1)

        guard let waiterToken = client.connectionIdWaiters.first?.key else {
            XCTFail("Should have a token")
            return
        }

        client.invalidateConnectionIdWaiter(waiterToken)

        XCTAssertEqual(client.connectionIdWaiters.count, 0)

        // We simulate connection id waiters completion to make sure the previously invalidated block is not executed
        client.completeConnectionIdWaiters(connectionId: nil)
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
    
    // MARK: - Background workers tests
    
    func test_productionClientIsInitalizedWithAllMandatoryBackgroundWorkers() {
        let config = inMemoryStorageConfig

        // Create a new chat client
        var client: ChatClient! = ChatClient(config: config)
        
        client.connectAnonymousUser()
        
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
        chatClient.connectUser(userInfo: .init(id: currentUserId), token: .unique(userId: currentUserId))
        
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
                    chatClient.connectUser(userInfo: .init(id: currentUserId), token: .unique(userId: currentUserId))

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
    
    // MARK: - Connect
    
    func test_reloadUserIfNeededIsCalled_whenClientIsInitialized_andErrorIsPropagated() throws {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient(
                config: inMemoryStorageConfig,
                environment: testEnv.environment
            )
            
            // WHEN
            let token = Token.unique()
            var connectCompletionCalled = false
            var connectCompletionError: Error?
            client.connectUser(
                userInfo: .init(id: .unique),
                tokenProvider: { $0(.success(token)) },
                completion: {
                    connectCompletionCalled = true
                    connectCompletionError = $0
                }
            )
            
            // THEN
            var providedToken: Token?
            client.userConnectionProvider?.tokenProvider { providedToken = try? $0.get() }
            XCTAssertEqual(providedToken, token)
            
            XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 1)

            // WHEN
            testEnv.clientUpdater?.reloadUserIfNeeded_completion!(error)
            
            // THEN
            XCTAssertEqual(connectCompletionError as? TestError, error)
            XCTAssertTrue(connectCompletionCalled)
        }
    }
    
    func test_connectUserWithToken_setsTokenProvider_andInitiatesConnection() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient(
                config: inMemoryStorageConfig,
                environment: testEnv.environment
            )
            
            // WHEN
            let token = Token.unique()
            var connectCompletionCalled = false
            var connectCompletionError: Error?
            client.connectUser(
                userInfo: .init(id: .unique),
                token: token,
                completion: {
                    connectCompletionCalled = true
                    connectCompletionError = $0
                }
            )
            
            // THEN
            var providedToken: Token?
            client.userConnectionProvider?.tokenProvider { providedToken = try? $0.get() }
            XCTAssertEqual(providedToken, token)
            
            XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 1)
            
            // WHEN
            testEnv.clientUpdater?.reloadUserIfNeeded_completion!(error)
            
            // THEN
            XCTAssertEqual(connectCompletionError as? TestError, error)
            XCTAssertTrue(connectCompletionCalled)
        }
    }
    
    func test_connectGuestUser_setsTokenProvider_andInitiatesConnection() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient(
                config: inMemoryStorageConfig,
                environment: testEnv.environment
            )
            
            // WHEN
            let user = UserInfo(
                id: .unique,
                name: .unique,
                imageURL: .localYodaImage,
                extraData: [:]
            )
            var connectCompletionCalled = false
            var connectCompletionError: Error?
            client.connectGuestUser(userInfo: user) {
                connectCompletionCalled = true
                connectCompletionError = $0
            }
            
            // THEN
            XCTAssertNotNil(client.userConnectionProvider)
            XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 1)
            
            // WHEN
            testEnv.clientUpdater?.reloadUserIfNeeded_completion!(error)
            XCTAssertEqual(connectCompletionError as? TestError, error)
            
            // THEN
            XCTAssertTrue(connectCompletionCalled)
        }
    }
    
    func test_connectAnonymoususer_setsTokenProvider_andInitiatesConnection() {
        for error in [nil, TestError()] {
            // GIVEN
            let client = ChatClient(
                config: inMemoryStorageConfig,
                environment: testEnv.environment
            )
            
            // WHEN
            var connectCompletionCalled = false
            var connectCompletionError: Error?
            client.connectAnonymousUser {
                connectCompletionCalled = true
                connectCompletionError = $0
            }
            
            // THEN
            var providedToken: Token?
            client.userConnectionProvider?.tokenProvider { providedToken = try? $0.get() }
            XCTAssertEqual(providedToken?.userId.isAnonymousUser, true)
            
            XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 1)

            // WHEN
            testEnv.clientUpdater?.reloadUserIfNeeded_completion!(error)
            
            // THEN
            XCTAssertEqual(connectCompletionError as? TestError, error)
            XCTAssertTrue(connectCompletionCalled)
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
        var providedConnectionId: ConnectionId? = .unique
        var connectionIdCallbackCalled = false
        client.provideConnectionId {
            providedConnectionId = $0
            connectionIdCallbackCalled = true
        }
        
        AssertAsync.willBeTrue(connectionIdCallbackCalled)
        // Assert that `nil` id is provided by waiter
        XCTAssertNil(providedConnectionId)
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
            },
            timerType: VirtualTimeTimer.self
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
