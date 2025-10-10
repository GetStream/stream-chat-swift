//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        testEnv.connectionRepository?.cleanUp()
        AssertAsync.canBeReleased(&testEnv)
        VirtualTimeTimer.invalidate()
        time = nil
        userId = nil
        super.tearDown()
    }

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

    func test_multipleInstance_whenLocalStorageURLIsTheSame() {
        let client1 = ChatClient(config: ChatClientConfig(apiKeyString: "123"))
        let client2 = ChatClient(config: ChatClientConfig(apiKeyString: "123"))
        XCTAssertEqual(1, ChatClient.activeLocalStorageURLs.value.count)
        // We only log an error when misuse happens
        XCTAssertEqual(
            client1.databaseContainer.persistentStoreDescriptions.compactMap(\.url),
            client2.databaseContainer.persistentStoreDescriptions.compactMap(\.url)
        )
    }
    
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

        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.connectionRepositoryBuilder = {
            ConnectionRepository_Mock(isClientInActiveMode: $0, syncRepository: $1, webSocketClient: $2, apiClient: $3, timerType: $4)
        }
        env.databaseContainerBuilder = { [config] kind, clientConfig in
            XCTAssertEqual(
                kind,
                .onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString))
            )
            XCTAssertEqual(clientConfig.shouldFlushLocalStorageOnStart, config.shouldFlushLocalStorageOnStart)
            XCTAssertEqual(clientConfig.isClientInActiveMode, config.isClientInActiveMode)
            XCTAssertEqual(clientConfig.localCaching, config.localCaching)
            XCTAssertEqual(clientConfig.deletedMessagesVisibility, config.deletedMessagesVisibility)
            XCTAssertEqual(clientConfig.shouldShowShadowedMessages, config.shouldShowShadowedMessages)
            return DatabaseContainer_Spy()
        }

        // Create a `Client` and assert that a DB file is created on the provided URL + APIKey path
        _ = ChatClient(
            config: config,
            environment: env
        )
    }

    func test_clientDatabaseStackInitialization_whenLocalStorageDisabled() {
        // Prepare a config with the in-memory storage
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false

        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.connectionRepositoryBuilder = {
            ConnectionRepository_Mock(isClientInActiveMode: $0, syncRepository: $1, webSocketClient: $2, apiClient: $3, timerType: $4)
        }
        env.databaseContainerBuilder = { kind, _ in
            XCTAssertEqual(kind, .inMemory)
            return DatabaseContainer_Spy()
        }

        // Create a `Client` and assert the correct DB kind is used
        _ = ChatClient(
            config: config,
            environment: env
        )
    }

    /// When the initialization of a local DB fails for some reason (i.e. incorrect URL),
    /// use a DB in the in-memory configuration
    func test_clientDatabaseStackInitialization_useInMemoryWhenOnDiskFails() {
        // Prepare a config with nil local storage
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = true
        config.localStorageFolderURL = nil

        // Create env object and store all `kinds it's called with.
        var env = ChatClient.Environment()
        env.connectionRepositoryBuilder = {
            ConnectionRepository_Mock(isClientInActiveMode: $0, syncRepository: $1, webSocketClient: $2, apiClient: $3, timerType: $4)
        }
        env.databaseContainerBuilder = { kind, _ in
            XCTAssertEqual(.inMemory, kind)
            return DatabaseContainer_Spy()
        }

        // Create a chat client and assert `Client` tries to initialize the local DB, and when it fails, it falls back
        // to the in-memory option.
        _ = ChatClient(
            config: config,
            environment: env
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

    func test_disconnect_flushesRequestsQueue() throws {
        // Create a chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())

        // Disconnect chat client
        let expectation = self.expectation(description: "disconnect completes")
        client.disconnect {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // Assert client is not recreated
        XCTAssertTrue(testEnv.apiClient! === client.apiClient)
        // Assert `disconnect` on updater is triggered
        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: testEnv.connectionRepository!)
        // Assert source is user initiated
        XCTAssertEqual(testEnv.connectionRepository!.disconnectSource, .userInitiated)
    }

    func test_logout_disconnectsAndRemovesLocalData() throws {
        // GIVEN
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())

        // WHEN
        let expectation = self.expectation(description: "logout completes")
        client.logout {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: testEnv.connectionRepository!)
        XCTAssertTrue(testEnv.databaseContainer!.removeAllData_called)
    }

    func test_logout_whenCurrentDevice_removesDevice() throws {
        // GIVEN
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())

        // WHEN
        let userId = UserId.unique
        testEnv.authenticationRepository?.mockedCurrentUserId = userId
        try testEnv.databaseContainer?.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .admin))
            try $0.saveCurrentDevice(.unique)
        }

        let expectation = self.expectation(description: "logout completes")
        client.logout {
            expectation.fulfill()
        }
        /// Erasing current user id should be called right after calling logout.
        XCTAssertCall(AuthenticationRepository_Mock.Signature.clearCurrentUserId, on: testEnv.authenticationRepository!)

        // THEN
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: testEnv.connectionRepository!)
        XCTAssertEqual(testEnv.apiClient?.request_endpoint?.path, .devices)
        XCTAssertEqual(testEnv.apiClient?.request_endpoint?.method, .delete)
    }

    func test_logout_whenNoCurrentDevice_doesNotRemoveDevice_shouldClearToken() throws {
        // GIVEN
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())

        // WHEN
        let userId = UserId.unique
        testEnv.authenticationRepository?.mockedCurrentUserId = userId
        try testEnv.databaseContainer?.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .admin))
        }
        let expectation = self.expectation(description: "logout completes")
        client.logout {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: testEnv.connectionRepository!)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.logOut, on: testEnv.authenticationRepository!)
        XCTAssertNil(testEnv.apiClient?.request_endpoint?.path)
        XCTAssertNil(testEnv.apiClient?.request_endpoint?.method)
    }

    func test_logout_whenRemoveDeviceIsFalse_doesNotRemoveDevice() throws {
        // GIVEN
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())

        // WHEN
        let userId = UserId.unique
        testEnv.authenticationRepository?.mockedCurrentUserId = userId
        try testEnv.databaseContainer?.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .admin))
            try $0.saveCurrentDevice(.unique)
        }
        let expectation = self.expectation(description: "logout completes")
        client.logout(removeDevice: false) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: testEnv.connectionRepository!)
        XCTAssertNil(testEnv.apiClient?.request_endpoint?.path)
        XCTAssertNil(testEnv.apiClient?.request_endpoint?.method)
    }

    func test_logout_clearsActiveControllers() throws {
        // GIVEN
        let client = ChatClient(
            config: inMemoryStorageConfig,
            environment: testEnv.environment
        )
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())
        client.syncRepository.startTrackingChannelController(ChannelControllerSpy())
        client.syncRepository.startTrackingChannelListController(ChatChannelListController_Mock.mock())

        XCTAssertEqual(client.syncRepository.activeChannelControllers.count, 1)
        XCTAssertEqual(client.syncRepository.activeChannelListControllers.count, 1)

        // WHEN
        let expectation = self.expectation(description: "logout completes")
        client.logout {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        XCTAssertEqual(client.syncRepository.activeChannelControllers.count, 0)
        XCTAssertEqual(client.syncRepository.activeChannelListControllers.count, 0)
    }

    func test_apiClient_usesInjectedURLSessionConfiguration() {
        // configure a URLSessionConfiguration with a URLProtocol class
        var urlSessionConfiguration = URLSessionConfiguration.default
        URLProtocol_Mock.startTestSession(with: &urlSessionConfiguration)
        
        // initialise a ChatClient with a custom URLSessionConfiguration,
        // which is used instead of `URLSessionConfiguration.default`
        var chatClientConfig = ChatClientConfig()
        chatClientConfig.urlSessionConfiguration = urlSessionConfiguration
        let chatClient = ChatClient(config: chatClientConfig)
        
        // make sure the `apiClient` is initialised using the injected
        // `URLSessionConfiguration`
        XCTAssertTrue(chatClient.apiClient.session.configuration.protocolClasses?
            .contains(where: { $0 is URLProtocol_Mock.Type }) ?? false)
    }

    // MARK: - Background workers tests

    func test_productionClientIsInitalizedWithAllMandatoryBackgroundWorkers() {
        let config = inMemoryStorageConfig

        // Create a new chat client
        let client: ChatClient! = ChatClient(config: config)

        let expectation = self.expectation(description: "Connect completes")
        client.connectAnonymousUser { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // Check all the mandatory background workers are initialized
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageSender })
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageEditor })
        XCTAssert(client.backgroundWorkers.contains { $0 is AttachmentQueueUploader })
        XCTAssertNotNil(client.connectionRecoveryHandler)
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

    // MARK: - Connect Token Provider

    func test_connectUser_tokenProvider_callsAuthenticationRepository_propagatesError() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let testError = TestError()
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        authenticationRepository.connectUserResult = .failure(testError)
        let receivedError = try waitFor { done in
            client.connectUser(userInfo: userInfo, tokenProvider: { _ in }, completion: done)
        }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertEqual(receivedError, testError)
    }

    func test_connectUser_tokenProvider_callsAuthenticationRepository_success() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        let reconnectionTimeoutHandler = try XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        let connectionRecoveryHandler = try XCTUnwrap(client.connectionRecoveryHandler as? ConnectionRecoveryHandler_Mock)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)

        authenticationRepository.connectUserResult = .success(())
        let receivedError = try waitFor { done in
            client.connectUser(userInfo: userInfo, tokenProvider: { _ in }, completion: done)
        }

        XCTAssertNil(receivedError)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.initialize, on: connectionRepository)
        XCTAssertEqual(reconnectionTimeoutHandler.startCallCount, 1)
        XCTAssertEqual(connectionRecoveryHandler.startCallCount, 1)
    }

    // MARK: - Connect Static Token

    func test_connectUser_staticToken_callsAuthenticationRepository_propagatesError() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let testError = TestError()
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        authenticationRepository.connectUserResult = .failure(testError)
        let receivedError = try waitFor { done in
            client.connectUser(userInfo: userInfo, token: .unique(), completion: done)
        }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertEqual(receivedError, testError)
    }

    func test_connectUser_staticToken_callsAuthenticationRepository_success() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        authenticationRepository.connectUserResult = .success(())
        let receivedError = try waitFor { done in
            client.connectUser(userInfo: userInfo, token: .unique(), completion: done)
        }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertNil(receivedError)
    }

    func test_connectUser_staticToken_expiringToken_returnsError() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        authenticationRepository.connectUserResult = .success(())
        let expiringToken = Token(rawValue: "", userId: "123", expiration: Date())
        let receivedError = try waitFor { done in
            client.connectUser(userInfo: userInfo, token: expiringToken, completion: done)
        }

        XCTAssertNotCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertTrue(receivedError is ClientError.MissingTokenProvider)
    }

    func test_connectUser_developmentToken_success() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        authenticationRepository.connectUserResult = .success(())
        let token = Token.development(userId: .unique)
        let receivedError = try waitFor { done in
            client.connectUser(userInfo: userInfo, token: token, completion: done)
        }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertNil(receivedError)
    }

    func test_connectUser_developmentToken_failure() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        let mockedError = TestError()
        authenticationRepository.connectUserResult = .failure(mockedError)
        let token = Token.development(userId: .unique)
        let receivedError = try waitFor { done in
            client.connectUser(userInfo: userInfo, token: token, completion: done)
        }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertEqual(receivedError, mockedError)
    }
    
    func test_connectUserAsync_staticToken_callsAuthenticationRepository_success() async throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let userInfo = UserInfo(id: "id")
        
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        authenticationRepository.connectUserResult = .success(())
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.provideConnectionIdResult = .success(.unique)
        try client.mockDatabaseContainer.createCurrentUser(id: userInfo.id)
        
        let connectedUser = try await client.connectUser(userInfo: userInfo, token: .unique())
        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectTokenProvider, on: authenticationRepository)
        XCTAssertCall("provideConnectionId(timeout:completion:)", on: connectionRepository)
        await XCTAssertEqual(userInfo.id, connectedUser.state.user.id)
    }

    // MARK: - Connect Guest

    func test_connectGuest_tokenProvider_callsAuthenticationRepository_propagatesError() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let testError = TestError()
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        authenticationRepository.connectGuestResult = .failure(testError)
        let receivedError = try waitFor { done in
            client.connectGuestUser(userInfo: userInfo, completion: done)
        }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectGuest, on: authenticationRepository)
        XCTAssertEqual(receivedError, testError)
    }

    func test_connectGuest_tokenProvider_callsAuthenticationRepository_success() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let userInfo = UserInfo(id: "id")
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        let reconnectionTimeoutHandler = try XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        let connectionRecoveryHandler = try XCTUnwrap(client.connectionRecoveryHandler as? ConnectionRecoveryHandler_Mock)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)

        authenticationRepository.connectGuestResult = .success(())
        let receivedError = try waitFor { done in
            client.connectGuestUser(userInfo: userInfo, completion: done)
        }

        XCTAssertNil(receivedError)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectGuest, on: authenticationRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.initialize, on: connectionRepository)
        XCTAssertEqual(reconnectionTimeoutHandler.startCallCount, 1)
        XCTAssertEqual(connectionRecoveryHandler.startCallCount, 1)
    }

    // MARK: - Connect Anonymous

    func test_connectAnonymous_tokenProvider_callsAuthenticationRepository_propagatesError() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let testError = TestError()
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        authenticationRepository.connectAnonResult = .failure(testError)
        let receivedError = try waitFor { done in
            client.connectAnonymousUser(completion: done)
        }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectAnon, on: authenticationRepository)
        XCTAssertEqual(receivedError, testError)
    }

    func test_connectAnonymous_tokenProvider_callsAuthenticationRepository_success() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        let reconnectionTimeoutHandler = try XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        let connectionRecoveryHandler = try XCTUnwrap(client.connectionRecoveryHandler as? ConnectionRecoveryHandler_Mock)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)

        authenticationRepository.connectAnonResult = .success(())
        let receivedError = try waitFor { done in
            client.connectAnonymousUser(completion: done)
        }

        XCTAssertNil(receivedError)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.connectAnon, on: authenticationRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.initialize, on: connectionRepository)
        XCTAssertEqual(reconnectionTimeoutHandler.startCallCount, 1)
        XCTAssertEqual(connectionRecoveryHandler.startCallCount, 1)
    }

    // MARK: - Disconnect

    func test_disconnect_shouldCallConnectionRepository_andClearTokenProvider_andCancelTimers() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())

        let expectation = self.expectation(description: "disconnect completes")
        client.disconnect {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: connectionRepository)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.clearTokenProvider, on: authenticationRepository)
        XCTAssertEqual(client.mockAuthenticationRepository.resetCallCount, 1)
    }

    func test_logout_shouldDisconnect_logOut_andRemoveAllData() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        let databaseContainer = try XCTUnwrap(client.databaseContainer as? DatabaseContainer_Spy)
        connectionRepository.disconnectResult = .success(())

        let expectation = self.expectation(description: "logout completes")
        client.logout(removeDevice: false) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: connectionRepository)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.clearTokenProvider, on: authenticationRepository)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.logOut, on: authenticationRepository)
        XCTAssertTrue(databaseContainer.removeAllData_called)
    }

    // MARK: - Complete ConnectionId Waiters

    func test_completeConnectionIdWaiters_callsConnectionRepository() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)

        let connectionId = "123-connection"
        client.completeConnectionIdWaiters(connectionId: connectionId)

        XCTAssertCall(ConnectionRepository_Mock.Signature.completeConnectionIdWaiters, on: connectionRepository)
        XCTAssertEqual(connectionId, connectionRepository.completeWaitersConnectionId)
    }

    // MARK: - Complete Token Waiters

    func test_completeTokenWaiters_callsAuthenticationRepository() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        let token = Token.unique()
        client.completeTokenWaiters(token: token)

        XCTAssertCall(AuthenticationRepository_Mock.Signature.completeTokenWaiters, on: authenticationRepository)
        XCTAssertEqual(token, authenticationRepository.completeWaitersToken)
    }

    // MARK: - Set token

    func test_setToken_callsAuthenticationRepository() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        let token = Token.unique()
        client.setToken(token: token)

        XCTAssertCall(AuthenticationRepository_Mock.Signature.setToken, on: authenticationRepository)
        XCTAssertEqual(token, authenticationRepository.mockedToken)
    }

    // MARK: Provide token

    func test_provideToken_calls_authenticationRepository() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        client.provideToken { _ in }

        XCTAssertCall(AuthenticationRepository_Mock.Signature.provideToken, on: authenticationRepository)
    }

    // MARK: Provide connection id

    func test_provideConnectionId_calls_connectionRepository() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)

        client.provideConnectionId { _ in }

        XCTAssertCall(ConnectionRepository_Mock.Signature.provideConnectionId, on: connectionRepository)
    }

    // MARK: ConnectionStateDelegate

    func test_webSocketClientStateUpdate_calls_connectionRepository() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let webSocketClient = try XCTUnwrap(client.webSocketClient)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        let state = WebSocketConnectionState.connecting
        client.webSocketClient(webSocketClient, didUpdateConnectionState: state)

        XCTAssertCall(ConnectionRepository_Mock.Signature.handleConnectionUpdate, on: connectionRepository)
        XCTAssertEqual(connectionRepository.connectionUpdateState, state)
        XCTAssertNotCall(AuthenticationRepository_Mock.Signature.refreshToken, on: authenticationRepository)
    }

    func test_webSocketClientStateUpdate_calls_connectionRepository_expiredToken() throws {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let webSocketClient = try XCTUnwrap(client.webSocketClient)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)

        let state = WebSocketConnectionState.disconnected(source: .systemInitiated)
        connectionRepository.simulateExpiredTokenOnConnectionUpdate = true
        client.webSocketClient(webSocketClient, didUpdateConnectionState: state)

        XCTAssertCall(ConnectionRepository_Mock.Signature.handleConnectionUpdate, on: connectionRepository)
        XCTAssertEqual(connectionRepository.connectionUpdateState, state)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.refreshToken, on: authenticationRepository)
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

    func test_passiveClient_provideConnectionId_returnsImmediately() throws {
        // Create Client with inactive flag set
        let client = ChatClient(config: inactiveInMemoryStorageConfig)

        // Set a connection Id waiter
        let result = try waitFor { done in
            client.provideConnectionId(completion: done)
        }

        // Assert that `nil` id is provided by waiter
        XCTAssertNil(result.value)
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

    // MARK: - Reconnection Timeout Tests

    func test_reconnectionTimeoutHandler_isInitializedWithConfig() {
        // Given
        var config = inMemoryStorageConfig
        config.reconnectionTimeout = 20
        let client = ChatClient(config: config)

        // Then
        XCTAssertNotNil(client.reconnectionTimeoutHandler)
    }

    func test_reconnectionTimeoutHandler_notInitialisedIfTimeoutNotProvided() {
        // Given
        var config = inMemoryStorageConfig
        config.reconnectionTimeout = nil
        let client = ChatClient(config: config)

        // Then
        XCTAssertNil(client.reconnectionTimeoutHandler)
    }

    func test_reconnectionTimeoutHandler_startsOnConnect() {
        // Given
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let timerMock = try! XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        
        // When
        client.connectAnonymousUser()
        
        // Then
        XCTAssertEqual(timerMock.startCallCount, 1)
    }

    func test_reconnectionTimeoutHandler_stopsOnConnected() {
        // Given
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let timerMock = try! XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        
        // When
        client.webSocketClient(client.webSocketClient!, didUpdateConnectionState: .connected(connectionId: .unique))

        // Then
        XCTAssertEqual(timerMock.stopCallCount, 1)
    }

    func test_reconnectionTimeoutHandler_startsOnConnecting() {
        // Given
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let timerMock = try! XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        timerMock.isRunning = false
        
        // When
        client.webSocketClient(client.webSocketClient!, didUpdateConnectionState: .connecting)
        
        // Then
        XCTAssertEqual(timerMock.startCallCount, 1)
    }

    func test_reconnectionTimeoutHandler_whenRunning_doesNotStart() {
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let timerMock = try! XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        timerMock.isRunning = true
        
        // When
        client.webSocketClient(client.webSocketClient!, didUpdateConnectionState: .connecting)

        // Then
        XCTAssertEqual(timerMock.startCallCount, 0)
    }

    func test_reconnectionTimeout_onChange() throws {
        // Given
        let client = ChatClient(config: inMemoryStorageConfig, environment: testEnv.environment)
        let timerMock = try XCTUnwrap(client.reconnectionTimeoutHandler as? ScheduledStreamTimer_Mock)
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        let connectionRepository = try XCTUnwrap(client.connectionRepository as? ConnectionRepository_Mock)
        connectionRepository.disconnectResult = .success(())
        
        // When
        timerMock.onChange?()
        
        // Then
        XCTAssertCall(ConnectionRepository_Mock.Signature.disconnect, on: connectionRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.completeConnectionIdWaiters, on: connectionRepository)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.completeTokenWaiters, on: authenticationRepository)
        XCTAssertCall(AuthenticationRepository_Mock.Signature.completeTokenCompletions, on: authenticationRepository)
        XCTAssertEqual(connectionRepository.disconnectSource, .timeout(from: .initialized))
        XCTAssertEqual(authenticationRepository.resetCallCount, 1)
    }
}

/// A helper class which provides mock environment for Client.
private class TestEnvironment {
    @Atomic var apiClient: APIClient_Spy?
    @Atomic var webSocketClient: WebSocketClient_Mock?
    @Atomic var databaseContainer: DatabaseContainer_Spy?
    var authenticationRepository: AuthenticationRepository_Mock?

    @Atomic var requestEncoder: RequestEncoder_Spy?
    @Atomic var requestDecoder: RequestDecoder_Spy?

    @Atomic var eventDecoder: EventDecoder?

    @Atomic var notificationCenter: EventNotificationCenter?

    @Atomic var connectionRepository: ConnectionRepository_Mock?

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
                    attachmentDownloader: $3,
                    attachmentUploader: $4
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
                    chatClientConfig: $1
                )
                return self.databaseContainer!
            },
            reconnectionHandlerBuilder: { _ in
                ScheduledStreamTimer_Mock()
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
                self.notificationCenter = EventNotificationCenter_Mock(database: $0, manualEventHandler: $1)
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
            connectionRepositoryBuilder: {
                self.connectionRepository = ConnectionRepository_Mock(isClientInActiveMode: $0, syncRepository: $1, webSocketClient: $2, apiClient: $3, timerType: $4)
                return self.connectionRepository!
            },
            backgroundTaskSchedulerBuilder: {
                self.backgroundTaskScheduler = BackgroundTaskScheduler_Mock()
                return self.backgroundTaskScheduler!
            },
            timerType: VirtualTimeTimer.self,
            connectionRecoveryHandlerBuilder: { _, _, _, _, _, _ in
                ConnectionRecoveryHandler_Mock()
            },
            authenticationRepositoryBuilder: {
                self.authenticationRepository = AuthenticationRepository_Mock(
                    apiClient: $0,
                    databaseContainer: $1,
                    connectionRepository: $2,
                    tokenExpirationRetryStrategy: $3,
                    timerType: $4
                )
                return self.authenticationRepository!
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
