//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChatClient_Tests: StressTestCase {
    var userId: UserId!
    private var testEnv: TestEnvironment<NoExtraData>!
    
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
    }
    
    override func tearDown() {
        testEnv.apiClient?.cleanUp()
        testEnv.clientUpdater?.cleanUp()
        AssertAsync.canBeReleased(&testEnv)
        super.tearDown()
    }
    
    var workerBuilders: [WorkerBuilder] = [
        MessageSender<NoExtraData>.init,
        NewChannelQueryUpdater<NoExtraData>.init,
        NewUserQueryUpdater<NoExtraData>.init
    ]
    
    var eventWorkerBuilders: [EventWorkerBuilder] = [
        ChannelWatchStateUpdater<NoExtraData>.init
    ]
    
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
        
        var usedDatabaseKind: DatabaseContainer.Kind?
        var shouldFlushDBOnStart: Bool?
        var shouldResetEphemeralValues: Bool?
        var localCachingSettings: ChatClientConfig.LocalCaching?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = ChatClientUpdaterMock.init
        env.databaseContainerBuilder = { kind, shouldFlushOnStart, shouldResetEphemeralValuesOnStart, cachingSettings in
            usedDatabaseKind = kind
            shouldFlushDBOnStart = shouldFlushOnStart
            shouldResetEphemeralValues = shouldResetEphemeralValuesOnStart
            localCachingSettings = cachingSettings
            return DatabaseContainerMock()
        }
        
        // Create a `Client` and assert that a DB file is created on the provided URL + APIKey path
        _ = ChatClient(
            config: config,
            workerBuilders: [Worker.init],
            eventWorkerBuilders: [],
            environment: env
        )

        XCTAssertEqual(
            usedDatabaseKind,
            .onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString))
        )
        XCTAssertEqual(shouldFlushDBOnStart, config.shouldFlushLocalStorageOnStart)
        XCTAssertEqual(shouldResetEphemeralValues, config.isClientInActiveMode)
        XCTAssertEqual(localCachingSettings, config.localCaching)
    }
    
    func test_clientDatabaseStackInitialization_whenLocalStorageDisabled() {
        // Prepare a config with the in-memory storage
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
        
        var usedDatabaseKind: DatabaseContainer.Kind?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = ChatClientUpdaterMock.init
        env.databaseContainerBuilder = { kind, _, _, _ in
            usedDatabaseKind = kind
            return DatabaseContainerMock()
        }
        
        // Create a `Client` and assert the correct DB kind is used
        _ = ChatClient(
            config: config,
            workerBuilders: [Worker.init],
            eventWorkerBuilders: [],
            environment: env
        )
        
        XCTAssertEqual(usedDatabaseKind, .inMemory)
    }
    
    /// When the initialization of a local DB fails for some reason (i.e. incorrect URL),
    /// use a DB in the in-memory configuration
    func test_clientDatabaseStackInitialization_useInMemoryWhenOnDiskFails() {
        // Prepare a config with the local storage
        let storeFolderURL = URL.newTemporaryDirectoryURL()
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = true
        config.localStorageFolderURL = storeFolderURL
        
        var usedDatabaseKinds: [DatabaseContainer.Kind] = []
        
        // Prepare a queue with errors the db builder should return. We want to return an error only the first time
        // when we expect the DB is created with the local DB option and we want it to fail.
        var errorsToReturn = Queue<Error>()
        errorsToReturn.push(TestError())

        // Create env object and store all `kinds it's called with.
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = ChatClientUpdaterMock.init
        env.databaseContainerBuilder = { kind, _, _, _ in
            usedDatabaseKinds.append(kind)
            // Return error for the first time
            if let error = errorsToReturn.pop() {
                throw error
            }
            // Return a new container the second time
            return DatabaseContainerMock()
        }
        
        // Create a chat client and assert `Client` tries to initialize the local DB, and when it fails, it falls back
        // to the in-memory option.
        _ = ChatClient(
            config: config,
            workerBuilders: [Worker.init],
            eventWorkerBuilders: [],
            environment: env
        )
        
        XCTAssertEqual(
            usedDatabaseKinds,
            [.onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString)), .inMemory]
        )
    }
    
    // MARK: - WebSocketClient tests
    
    func test_webSocketClientConfiguration() throws {
        // Use in-memory store
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: eventWorkerBuilders,
            environment: testEnv.environment
        )
        
        client.connectAnonymousUser()

        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Assert the init parameters are correct
        let webSocket = testEnv.webSocketClient
        assertMandatoryHeaderFields(webSocket?.init_sessionConfiguration)
        XCTAssertEqual(webSocket?.init_sessionConfiguration.waitsForConnectivity, false)
        XCTAssert(webSocket?.init_requestEncoder is TestRequestEncoder)
        XCTAssert(webSocket?.init_eventNotificationCenter.database === client.databaseContainer)
        XCTAssertNotNil(webSocket?.init_eventDecoder)
        
        // EventDataProcessorMiddleware must be always first
        XCTAssert(webSocket?.init_eventNotificationCenter.middlewares[0] is EventDataProcessorMiddleware<NoExtraData>)
        
        // Assert Client sets itself as delegate for the request encoder
        XCTAssert(webSocket?.init_requestEncoder.connectionDetailsProviderDelegate === client)
    }
    
    func test_webSocketClient_hasAllMandatoryMiddlewares() throws {
        // Use in-memory store
        // Create a new chat client, which in turn creates a webSocketClient
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )

        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Assert that mandatory middlewares exists
        let middlewares = try XCTUnwrap(testEnv.webSocketClient?.init_eventNotificationCenter.middlewares)
        
        // Assert `EventDataProcessorMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is EventDataProcessorMiddleware<NoExtraData> }))
        // Assert `TypingStartCleanupMiddleware` exists
        let typingStartCleanupMiddlewareIndex = middlewares.firstIndex { $0 is TypingStartCleanupMiddleware<NoExtraData> }
        XCTAssertNotNil(typingStartCleanupMiddlewareIndex)
        // Assert `ChannelReadUpdaterMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is ChannelReadUpdaterMiddleware<NoExtraData> }))
        // Assert `ChannelMemberTypingStateUpdaterMiddleware` exists
        let typingStateUpdaterMiddlewareIndex = middlewares
            .firstIndex { $0 is ChannelMemberTypingStateUpdaterMiddleware<NoExtraData> }
        XCTAssertNotNil(typingStateUpdaterMiddlewareIndex)
        // Assert `ChannelMemberTypingStateUpdaterMiddleware` goes after `TypingStartCleanupMiddleware`
        XCTAssertTrue(typingStateUpdaterMiddlewareIndex! > typingStartCleanupMiddlewareIndex!)
        // Assert `MessageReactionsMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is MessageReactionsMiddleware<NoExtraData> }))
        // Assert `ChannelTruncatedEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is ChannelTruncatedEventMiddleware<NoExtraData> }))
        // Assert `MemberEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is MemberEventMiddleware<NoExtraData> }))
        // Assert `UserChannelBanEventsMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is UserChannelBanEventsMiddleware<NoExtraData> }))
        // Assert `UserWatchingEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is UserWatchingEventMiddleware<NoExtraData> }))
        // Assert `ChannelVisibilityEventMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is ChannelVisibilityEventMiddleware<NoExtraData> }))
    }
    
    func test_connectionStatus_isExposed() {
        let config = inMemoryStorageConfig

        // Create an environment.
        var clientUpdater: ChatClientUpdater<NoExtraData>?
        var env = ChatClient.Environment()
        env.clientUpdaterBuilder = {
            if let updater = clientUpdater {
                return updater
            } else {
                let updater = ChatClientUpdater<NoExtraData>(client: $0)
                clientUpdater = updater
                return updater
            }
        }

        // Create a new chat client.
        var initCompletionCalled = false
        let client = ChatClient(
            config: config,
            workerBuilders: [],
            eventWorkerBuilders: [],
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
        let error = ClientError(with: TestError())
        client.webSocketClient?.simulateConnectionStatus(.disconnected(error: error))

        // Assert the WSConnectionState is exposed as ChatClientConnectionStatus
        XCTAssertEqual(client.connectionStatus, .disconnected(error: error))
    }
    
    // MARK: - ConnectionDetailsProvider tests
    
    func test_clientProvidesConnectionId() throws {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
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
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
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
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .disconnected(error: error))
        
        // Assert the provided connection id is `nil`
        XCTAssertNil(providedConnectionId)
        
        // Simulate WebSocketConnection change to "connected" and assert `providedConnectionId` is still `nil`
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: .unique))

        XCTAssertNil(providedConnectionId)
    }
    
    func test_client_webSocketIsDisconnected_becauseTokenExpired_callsReloadUserIfNeeded() throws {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        
        client.connectAnonymousUser()
        client.tokenProvider = { $0(.success(.unique())) }

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
        let error = ClientError(with: ErrorPayload(code: 40, message: "", statusCode: 200))
        testEnv.webSocketClient?
            .connectionStateDelegate?
            .webSocketClient(
                testEnv.webSocketClient!,
                didUpdateConnectionState: .disconnected(error: error)
            )
        
        // Was called one more time on receiving token expired error
        XCTAssertEqual(testEnv.clientUpdater!.reloadUserIfNeeded_callsCount, 2)
        
        // We set connectionId to nil after token expiration disconnect
        XCTAssertNil(client.connectionId)
    }
    
    func test_clientProvidesConnectionId_afterUnlockingResources() {
        // IMPORTANT: This test hangs (freezes) if there's simulatenous
        // access to `connectionId`, so freeze = failure for this test
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
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
    
    // MARK: - APIClient tests
    
    func test_apiClientConfiguration() throws {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )

        // Simulate access to `apiClient` so it is initialized
        _ = client.apiClient
        
        assertMandatoryHeaderFields(testEnv.apiClient?.init_sessionConfiguration)
        XCTAssert(testEnv.apiClient?.init_requestDecoder is TestRequestDecoder)
        XCTAssert(testEnv.apiClient?.init_requestEncoder is TestRequestEncoder)
    }
    
    // MARK: - Background workers tests
    
    func test_productionClientIsInitalizedWithAllMandatoryBackgroundWorkers() {
        let config = inMemoryStorageConfig

        // Create a new chat client
        var client: ChatClient! = ChatClient(config: config)
        
        client.connectAnonymousUser()
        
        // Check all the mandatory background workers are initialized
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageSender<NoExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is NewChannelQueryUpdater<NoExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is NewUserQueryUpdater<NoExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is ChannelWatchStateUpdater<NoExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageEditor<NoExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is MissingEventsPublisher<NoExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is AttachmentUploader })
        
        AssertAsync.canBeReleased(&client)
    }
    
    func test_backgroundWorkersConfiguration() {
        // Set up mocks for APIClient, WSClient and Database
        let config = ChatClientConfig(apiKey: .init(.unique))
        
        // Create a Client instance and check the workers are initialized properly
        let client = _ChatClient(
            config: config,
            workerBuilders: [TestWorker.init],
            eventWorkerBuilders: [TestEventWorker.init],
            environment: testEnv.environment
        )

        // Simulate `createBackgroundWorkers` so workers are created.
        client.createBackgroundWorkers()
        
        let testWorker = client.backgroundWorkers.first as? TestWorker
        XCTAssert(testWorker?.init_database is DatabaseContainerMock)
        XCTAssert(testWorker?.init_apiClient is APIClientMock)
        
        // Event workers are initialized after normal workers
        let testEventWorker = client.backgroundWorkers.last as? TestEventWorker
        XCTAssert(testEventWorker?.init_database is DatabaseContainerMock)
        XCTAssert(testEventWorker?.init_eventNotificationCenter is EventNotificationCenterMock)
        XCTAssert(testEventWorker?.init_apiClient is APIClientMock)
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
                        .webSocketConnect(userInfo: UserInfo<NoExtraData>(id: currentUserId))
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
    
    func test_reloadUserIfNeededIsCalled_whenClientIsInitialized_andErrorIsPropagated() {
        for error in [nil, TestError()] {
            var clientInitCompletionCalled = false
            var clientInitCompletionError: Error?

            // Create a client, provide the completion and catch the result.
            let client = ChatClient(
                config: inMemoryStorageConfig,
                workerBuilders: [],
                eventWorkerBuilders: [],
                environment: testEnv.environment
            )
            client.connectAnonymousUser { error in
                clientInitCompletionCalled = true
                clientInitCompletionError = error
            }

            // Assert `reloadUserIfNeeded` is called on `clientUpdater`.
            XCTAssertTrue(testEnv.clientUpdater!.reloadUserIfNeeded_called)

            // Simulate `reloadUserIfNeeded` completion result.
            testEnv.clientUpdater?.reloadUserIfNeeded_completion!(error)
            // Wait for `ChatClient.init` completion called.
            AssertAsync.willBeTrue(clientInitCompletionCalled)

            // Assert error from `reloadUserIfNeeded` is propagated.
            XCTAssertEqual(clientInitCompletionError as? TestError, error)
        }
    }
    
    func test_reloadUserIfNeededIsNotCalled_whenClientIsInitialized_andTokenProviderIsNil() {
        _ = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: [],
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        
        XCTAssert(testEnv.clientUpdater?.reloadUserIfNeeded_called != true)
    }
    
    func test_connectUser_setsTokenProvider_andInitiatesConnection() {
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: [],
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        let token = Token.unique()
        XCTAssert(testEnv.clientUpdater?.reloadUserIfNeeded_called != true)

        client.connectUser(
            userInfo: .init(id: .unique, name: "John Doe", imageURL: .unique(), extraData: .defaultValue),
            token: token
        )
        XCTAssertTrue(testEnv.clientUpdater!.reloadUserIfNeeded_called)
        
        var providedToken: Token?
        client.userConnectionProvider?.getToken(client) { providedToken = try! $0.get() }
        AssertAsync.willBeEqual(token, providedToken)
    }
    
    func test_connectGuestUser_setsTokenProvider_andInitiatesConnection() {
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: [],
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        let token = Token.unique()
        XCTAssert(testEnv.clientUpdater?.reloadUserIfNeeded_called != true)

        let userId = UserId.unique
        let name = "John Doe"
        client.connectGuestUser(
            userInfo: .init(
                id: userId,
                name: "John Doe",
                imageURL: .localYodaImage,
                extraData: .defaultValue
            )
        )
        
        XCTAssertTrue(testEnv.clientUpdater!.reloadUserIfNeeded_called)
        
        var providedToken: Token?
        client.userConnectionProvider?.getToken(client) { providedToken = try! $0.get() }
        
        let expectedEndpoint: Endpoint<GuestUserTokenPayload<NoExtraData>> = .guestUserToken(
            userId: userId,
            name: name,
            imageURL: .localYodaImage,
            extraData: .defaultValue
        )
        AssertAsync.willBeEqual(AnyEndpoint(expectedEndpoint), client.mockAPIClient.request_endpoint)
        
        let tokenResult: Result<GuestUserTokenPayload<NoExtraData>, Error> = .success(
            .init(user: .dummy(userId: userId, role: .guest), token: token)
        )
        client.mockAPIClient.test_simulateResponse(tokenResult)

        AssertAsync.willBeEqual(token, providedToken)
    }
    
    func test_connectAnonymoususer_setsTokenProvider_andInitiatesConnection() {
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: [],
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        XCTAssert(testEnv.clientUpdater?.reloadUserIfNeeded_called != true)

        client.connectAnonymousUser()
        XCTAssertTrue(testEnv.clientUpdater!.reloadUserIfNeeded_called)
        
        var providedToken: Token?
        client.userConnectionProvider?.getToken(client) { providedToken = try! $0.get() }
        AssertAsync.willBeTrue(providedToken != nil)
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
    
    // MARK: - App background behavior
    
    // App goes to background
    
    func test_backgroundTaskIsCreated_whenConfigAllows() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Assert that config allows background task
        assert(client.config.staysConnectedInBackground)
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Simulate .connected state to obtain connection id
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        XCTAssertEqual(client.connectionId, connectionId)
        
        // Simulate going into background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onBackground?()
        
        // Assert that background task is created
        XCTAssertEqual(testEnv.backgroundTaskScheduler?.beginBackgroundTask_called, true)
    }
    
    func test_backgroundTaskIsNotCreated_whenStayConnectedFlagIsNotSet() {
        // Create a new chat client
        var config = inMemoryStorageConfig
        config.staysConnectedInBackground = false
        let client = ChatClient(
            config: config,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Simulate .connected state to obtain connection id
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        XCTAssertEqual(client.connectionId, connectionId)
        
        // Simulate going into background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onBackground?()
        
        // Assert that background task is not created
        XCTAssertEqual(testEnv.backgroundTaskScheduler?.beginBackgroundTask_called, false)
        
        // Assert that `disconnect` is called immediately
        XCTAssertEqual(testEnv.clientUpdater?.disconnect_called, true)
    }
    
    func test_backgroundTaskIsNotCreated_ifNotConnected() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Simulate .disconnected state
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .disconnected(error: nil))
        
        // Simulate going into background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onBackground?()
        
        // Assert that background task is not created
        XCTAssertEqual(testEnv.backgroundTaskScheduler?.beginBackgroundTask_called, false)
    }
    
    func test_disconnectCalled_ifBackgroundTaskCreationFails() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Simulate .connected state to obtain connection id
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        XCTAssertEqual(client.connectionId, connectionId)
        
        // Simulate background task creation failure
        testEnv.backgroundTaskScheduler?.beginBackgroundTask_returns = false
        
        // Simulate going into background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onBackground?()
        
        // Assert that WS disconnect is called
        XCTAssertEqual(testEnv.clientUpdater?.disconnect_called, true)
    }
    
    func test_disconnectCalled_whenBackgroundTaskFinishes() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Simulate .connected state to obtain connection id
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        XCTAssertEqual(client.connectionId, connectionId)
        
        // Simulate going into background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onBackground?()
        
        // Assert that background task is created
        XCTAssertEqual(testEnv.backgroundTaskScheduler?.beginBackgroundTask_called, true)
        
        // Simulate background task execution finish
        testEnv.backgroundTaskScheduler?.beginBackgroundTask_expirationHandler?()
        
        // Assert that `disconnect` is called
        XCTAssertEqual(testEnv.clientUpdater?.disconnect_called, true)
        
        // Assert that background task is cancelled
        XCTAssertEqual(testEnv.backgroundTaskScheduler?.endBackgroundTask_called, true)
    }
    
    func test_backgroundTaskCancelled_whenAppIsForegrounded() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Simulate .connected state to obtain connection id
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConnectionState: .connected(connectionId: connectionId))
        
        XCTAssertEqual(client.connectionId, connectionId)
        
        // Simulate going into background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onBackground?()
        
        // Assert that background task is created
        XCTAssertEqual(testEnv.backgroundTaskScheduler?.beginBackgroundTask_called, true)
        
        // Simulate app waking from background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onForeground?()
        
        // Assert that background task is cancelled
        XCTAssertEqual(testEnv.backgroundTaskScheduler?.endBackgroundTask_called, true)
        
        // Assert that background task expiration handler is not called
        // by asserting that `disconnect` is not called
        XCTAssertEqual(testEnv.clientUpdater?.disconnect_called, false)
    }
    
    // App wakes from background
    
    func test_didBecomeActiveNotification_connectUserWasCalled_callsConnect() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Assert that `connect` is not called yet
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, false)
        
        // Simulate waking from background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onForeground?()
        
        // Assert that `connect` is called
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, true)
    }
    
    func test_didBecomeActiveNotification_connectUserWasNotCalled_doesNotCallConnect() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        _ = client.clientUpdater
        
        // Assert that `connect` is not called yet
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, false)
        
        // Simulate waking from background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onForeground?()
        
        // Assert that `connect` is called
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, false)
    }
    
    func test_didBecomeActiveNotification_connectedAndDiconnectedUser_shouldNotConnect() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        client.disconnect()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        // Assert that `connect` is not called yet
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, false)
        
        // Simulate waking from background
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onForeground?()
        
        // Assert that `connect` is called
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, false)
    }
    
    func test_didBecomeActiveNotification_connectedUserDiconnectedAndConnectedBack_shouldConnect() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        client.connectAnonymousUser()
        
        // Simulate access to `webSocketClient` so it is initialized
        _ = client.webSocketClient
        
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, false)

        client.disconnect()
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onForeground?()
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, false)

        client.connectAnonymousUser()
        testEnv.backgroundTaskScheduler?.startListeningForAppStateUpdates_onForeground?()
        XCTAssertEqual(testEnv.clientUpdater?.connect_called, true)
    }
}

class TestWorker: Worker {
    let id = UUID()
    
    var init_database: DatabaseContainer?
    var init_apiClient: APIClient?
    
    override init(database: DatabaseContainer, apiClient: APIClient) {
        init_database = database
        init_apiClient = apiClient
        
        super.init(database: database, apiClient: apiClient)
    }
}

class TestEventWorker: EventWorker {
    let id = UUID()
    
    var init_database: DatabaseContainer?
    var init_eventNotificationCenter: EventNotificationCenter?
    var init_apiClient: APIClient?
    
    override init(database: DatabaseContainer, eventNotificationCenter: EventNotificationCenter, apiClient: APIClient) {
        init_database = database
        init_eventNotificationCenter = eventNotificationCenter
        init_apiClient = apiClient
        
        super.init(database: database, eventNotificationCenter: eventNotificationCenter, apiClient: apiClient)
    }
}

/// A helper class which provides mock environment for Client.
private class TestEnvironment<ExtraData: ExtraDataTypes> {
    @Atomic var apiClient: APIClientMock?
    @Atomic var webSocketClient: WebSocketClientMock?
    @Atomic var databaseContainer: DatabaseContainerMock?
    
    @Atomic var requestEncoder: TestRequestEncoder?
    @Atomic var requestDecoder: TestRequestDecoder?
    
    @Atomic var eventDecoder: EventDecoder<ExtraData>?
    
    @Atomic var notificationCenter: EventNotificationCenter?

    @Atomic var clientUpdater: ChatClientUpdaterMock<ExtraData>?
    
    @Atomic var backgroundTaskScheduler: MockBackgroundTaskScheduler?
    
    lazy var environment: _ChatClient<ExtraData>.Environment = { [unowned self] in
        .init(
            apiClientBuilder: {
                self.apiClient = APIClientMock(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    requestDecoder: $2,
                    CDNClient: $3
                )
                return self.apiClient!
            },
            webSocketClientBuilder: {
                self.webSocketClient = WebSocketClientMock(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    eventDecoder: $2,
                    eventNotificationCenter: $3,
                    internetConnection: $4
                )
                return self.webSocketClient!
            },
            databaseContainerBuilder: {
                self.databaseContainer = try! DatabaseContainerMock(
                    kind: $0,
                    shouldFlushOnStart: $1,
                    shouldResetEphemeralValuesOnStart: $2,
                    localCachingSettings: $3
                )
                return self.databaseContainer!
            },
            requestEncoderBuilder: {
                if let encoder = self.requestEncoder {
                    return encoder
                }
                self.requestEncoder = TestRequestEncoder(baseURL: $0, apiKey: $1)
                return self.requestEncoder!
            },
            requestDecoderBuilder: {
                self.requestDecoder = TestRequestDecoder()
                return self.requestDecoder!
            },
            eventDecoderBuilder: {
                self.eventDecoder = EventDecoder<ExtraData>()
                return self.eventDecoder!
            },
            notificationCenterBuilder: {
                self.notificationCenter = EventNotificationCenterMock(database: $0)
                return self.notificationCenter!
            },
            clientUpdaterBuilder: {
                self.clientUpdater = ChatClientUpdaterMock(client: $0)
                return self.clientUpdater!
            },
            backgroundTaskSchedulerBuilder: {
                self.backgroundTaskScheduler = MockBackgroundTaskScheduler()
                return self.backgroundTaskScheduler!
            }
        )
    }()
}

extension ChatClient_Tests {
    /// Asserts that URLSessionConfiguration contains all require header fields
    private func assertMandatoryHeaderFields(
        _ config: URLSessionConfiguration?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let config = config else {
            XCTFail("Config is `nil`", file: file, line: line)
            return
        }
        
        let headers = config.httpAdditionalHeaders as? [String: String] ?? [:]
        XCTAssertEqual(
            headers["X-Stream-Client"],
            "stream-chat-swift-client-v\(SystemEnvironment.version)"
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

// MARK: - Mock

class EventNotificationCenterMock: EventNotificationCenter {
    /// Logs all events the `process` method was called with
    @Atomic var process_loggedEvents: [Event] = []
    
    override func process(_ event: Event) {
        super.process(event)
        _process_loggedEvents { $0.append(event) }
    }
}
