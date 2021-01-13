//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

class ChatClient_Tests: StressTestCase {
    var userId: UserId!
    private var testEnv: TestEnvironment<DefaultExtraData>!
    
    // A helper providing ChatClientConfig with in-memory DB option
    var inMemoryStorageConfig: ChatClientConfig {
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
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
        AssertAsync.canBeReleased(&testEnv)
        super.tearDown()
    }
    
    var workerBuilders: [WorkerBuilder] = [
        MessageSender<DefaultExtraData>.init,
        NewChannelQueryUpdater<DefaultExtraData>.init,
        NewUserQueryUpdater<DefaultExtraData.User>.init
    ]
    
    var eventWorkerBuilders: [EventWorkerBuilder] = [
        ChannelWatchStateUpdater<DefaultExtraData>.init
    ]
    
    // MARK: - Database stack tests
    
    func test_clientDatabaseStackInitialization_whenLocalStorageEnabled_respectsConfigValues() {
        // Prepare a config with the local storage
        let storeFolderURL = URL.newTemporaryDirectoryURL()
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = true
        config.shouldFlushLocalStorageOnStart = true
        config.localStorageFolderURL = storeFolderURL
        
        var usedDatabaseKind: DatabaseContainer.Kind?
        var shouldFlushDBOnStart: Bool?
        var shouldResetEphemeralValues: Bool?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { kind, shouldFlushOnStart, shouldResetEphemeralValuesOnStart in
            usedDatabaseKind = kind
            shouldFlushDBOnStart = shouldFlushOnStart
            shouldResetEphemeralValues = shouldResetEphemeralValuesOnStart
            return DatabaseContainerMock()
        }
        
        // Create a `Client` and assert that a DB file is created on the provided URL + APIKey path
        _ = ChatClient(config: config, workerBuilders: [Worker.init], eventWorkerBuilders: [], environment: env)
        XCTAssertEqual(
            usedDatabaseKind,
            .onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString))
        )
        XCTAssertEqual(shouldFlushDBOnStart, config.shouldFlushLocalStorageOnStart)
        XCTAssertEqual(shouldResetEphemeralValues, config.isClientInActiveMode)
    }
    
    func test_clientDatabaseStackInitialization_whenLocalStorageDisabled() {
        // Prepare a config with the in-memory storage
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
        
        var usedDatabaseKind: DatabaseContainer.Kind?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { kind, _, _ in
            usedDatabaseKind = kind
            return DatabaseContainerMock()
        }
        
        // Create a `Client` and assert the correct DB kind is used
        _ = ChatClient(config: config, workerBuilders: [Worker.init], eventWorkerBuilders: [], environment: env)
        
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
        env.databaseContainerBuilder = { kind, _, _ in
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
        _ = ChatClient(config: config, workerBuilders: [Worker.init], eventWorkerBuilders: [], environment: env)
        
        XCTAssertEqual(
            usedDatabaseKinds,
            [.onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString)), .inMemory]
        )
    }
    
    // MARK: - WebSocketClient tests
    
    func test_webSocketClientIsInitialized() throws {
        // Use in-memory store
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: eventWorkerBuilders,
            environment: testEnv.environment
        )
        
        // Assert the init parameters are correct
        let webSocket = testEnv.webSocketClient
        assertMandatoryHeaderFields(webSocket?.init_sessionConfiguration)
        XCTAssert(webSocket?.init_requestEncoder is TestRequestEncoder)
        XCTAssertNotNil(webSocket?.init_eventDecoder)
        
        // EventDataProcessorMiddleware must be always first
        XCTAssert(webSocket?.init_eventNotificationCenter.middlewares[0] is EventDataProcessorMiddleware<DefaultExtraData>)
        
        // Assert Client sets itself as delegate for the request encoder
        XCTAssert(webSocket?.init_requestEncoder.connectionDetailsProviderDelegate === client)
    }
    
    func test_webSocketClient_hasAllMandatoryMiddlewares() throws {
        // Use in-memory store
        // Create a new chat client, which in turn creates a webSocketClient
        _ = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        
        // Assert that mandatory middlewares exists
        let middlewares = try XCTUnwrap(testEnv.webSocketClient?.init_eventNotificationCenter.middlewares)
        
        // Assert `EventDataProcessorMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is EventDataProcessorMiddleware<DefaultExtraData> }))
        // Assert `TypingStartCleanupMiddleware` exists
        let typingStartCleanupMiddlewareIndex = middlewares.firstIndex { $0 is TypingStartCleanupMiddleware<DefaultExtraData> }
        XCTAssertNotNil(typingStartCleanupMiddlewareIndex)
        // Assert `ChannelReadUpdaterMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is ChannelReadUpdaterMiddleware<DefaultExtraData> }))
        // Assert `ChannelMemberTypingStateUpdaterMiddleware` exists
        let typingStateUpdaterMiddlewareIndex = middlewares
            .firstIndex { $0 is ChannelMemberTypingStateUpdaterMiddleware<DefaultExtraData> }
        XCTAssertNotNil(typingStateUpdaterMiddlewareIndex)
        // Assert `ChannelMemberTypingStateUpdaterMiddleware` goes after `TypingStartCleanupMiddleware`
        XCTAssertTrue(typingStateUpdaterMiddlewareIndex! > typingStartCleanupMiddlewareIndex!)
        // Assert `MessageReactionsMiddleware` exists
        XCTAssert(middlewares.contains(where: { $0 is MessageReactionsMiddleware<DefaultExtraData> }))
    }
    
    func test_connectionStatus_isExposed() {
        // Create a new chat client
        let client = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )

        // Simulate connection state change of WSClient
        let error = ClientError(with: TestError())
        testEnv.webSocketClient?.simulateConnectionStatus(.disconnected(error: error))
        
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
        
        // Set a connection Id waiter and assert it's `nil`
        var providedConnectionId: ConnectionId?
        client.provideConnectionId {
            providedConnectionId = $0
        }
        XCTAssertNil(providedConnectionId)
        
        // Simulate WebSocketConnection change
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConectionState: .connecting)
        
        AssertAsync.staysTrue(providedConnectionId == nil)
        
        // Simulate WebSocket connected and connection id is provided
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConectionState: .connecting)
        let connectionId: ConnectionId = .unique
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConectionState: .connected(connectionId: connectionId))
        
        AssertAsync.willBeEqual(providedConnectionId, connectionId)
        XCTAssertEqual(try await { client.provideConnectionId(completion: $0) }, connectionId)
        
        // Simulate WebSocketConnection disconnecting and assert connectionId is reset
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConectionState: .connecting)
        
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
        
        // Set a connection Id waiter and set `providedConnectionId` to a non-nil value
        var providedConnectionId: ConnectionId? = .unique
        client.provideConnectionId {
            providedConnectionId = $0
        }
        XCTAssertNotNil(providedConnectionId)
        
        // Simulate WebSocketConnection change to "disconnected"
        let error = ClientError(with: TestError())
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConectionState: .disconnected(error: error))
        
        // Assert the provided connection id is `nil`
        XCTAssertNil(providedConnectionId)
        
        // Simulate WebSocketConnection change to "connected" and assert `providedConnectionId` is still `nil`
        testEnv.webSocketClient?.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConectionState: .connected(connectionId: .unique))

        XCTAssertNil(providedConnectionId)
    }
    
    func test_clientProvidesToken_fromTokenProvider() throws {
        let newUserId: UserId = .unique
        let newToken: Token = .unique
        
        var config = inMemoryStorageConfig
        config.tokenProvider = { apiKey, userId, completion in
            XCTAssertEqual(apiKey, config.apiKey)
            XCTAssertEqual(userId, newUserId)
            completion(newToken)
        }
        
        // Create a new chat client
        let client = ChatClient(
            config: config,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        
        // Assert the token of anonymous user is `nil`
        XCTAssertNil(client.provideToken())
        
        // Set a new user without an explicit token
        client.currentUserController().setUser(userId: newUserId, name: nil, imageURL: nil)
        
        AssertAsync.willBeEqual(client.provideToken(), newToken)
    }
    
    // MARK: - APIClient tests
    
    func test_apiClientIsInitialized() throws {
        // Create a new chat client
        _ = ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: [],
            environment: testEnv.environment
        )
        
        assertMandatoryHeaderFields(testEnv.apiClient?.init_sessionConfiguration)
        XCTAssert(testEnv.apiClient?.init_requestDecoder is TestRequestDecoder)
        XCTAssert(testEnv.apiClient?.init_requestEncoder is TestRequestEncoder)
    }
    
    // MARK: - Background workers tests
    
    func test_productionClientIsInitalizedWithAllMandatoryBackgroundWorkers() {
        // Create a new Client with production configuration
        let config = ChatClientConfig(apiKey: .init(.unique))
        let client = _ChatClient<DefaultExtraData>(config: config)
        
        // Check all the mandatory background workers are initialized
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageSender<DefaultExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is NewChannelQueryUpdater<DefaultExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is NewUserQueryUpdater<DefaultExtraData.User> })
        XCTAssert(client.backgroundWorkers.contains { $0 is ChannelWatchStateUpdater<DefaultExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageEditor<DefaultExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is MissingEventsPublisher<DefaultExtraData> })
        XCTAssert(client.backgroundWorkers.contains { $0 is AttachmentUploader<DefaultExtraData> })
    }
    
    func test_backgroundWorkersAreInitialized() {
        // Set up mocks for APIClient, WSClient and Database
        let config = ChatClientConfig(apiKey: .init(.unique))
        
        // Create a Client instance and check the workers are initialized properly
        let client = _ChatClient(
            config: config,
            workerBuilders: [TestWorker.init],
            eventWorkerBuilders: [TestEventWorker.init],
            environment: testEnv.environment
        )
        
        let testWorker = client.backgroundWorkers.first as? TestWorker
        XCTAssert(testWorker?.init_database is DatabaseContainerMock)
        XCTAssert(testWorker?.init_apiClient is APIClientMock)
        
        // Event workers are initialized after normal workers
        let testEventWorker = client.backgroundWorkers.last as? TestEventWorker
        XCTAssert(testEventWorker?.init_database is DatabaseContainerMock)
        XCTAssert(testEventWorker?.init_eventNotificationCenter is EventNotificationCenterMock)
        XCTAssert(testEventWorker?.init_apiClient is APIClientMock)
    }
    
    // MARK: - Setting a new current user tests
    
    func test_currentUserId_isNilInitially() {
        let client = ChatClient(config: inMemoryStorageConfig)
        
        XCTAssertNil(client.currentUserId)
        XCTAssertNil(testEnv.databaseContainer?.viewContext.currentUser())
    }
    
    func test_settingUser_resetsBackgroundWorkers() {
        // Create ChatClient with TestWorker and TestEventWorker only
        let client = _ChatClient(
            config: inMemoryStorageConfig,
            workerBuilders: [TestWorker.init],
            eventWorkerBuilders: [TestEventWorker.init],
            environment: testEnv.environment
        )
        
        let currentUserController = client.currentUserController()

        // Generate userIds for first user
        let oldUserId: UserId = .unique
        let oldUserToken: Token = .unique
        
        // Set a user
        currentUserController.setUser(userId: oldUserId, name: nil, imageURL: nil, token: oldUserToken)

        // Save worker's UUID
        let oldWorkerUUID = (client.backgroundWorkers.first as! TestWorker).id
        let oldEventWorkerUUID = (client.backgroundWorkers.last as! TestEventWorker).id
        
        // Set the same user again
        currentUserController.setUser(userId: oldUserId, name: nil, imageURL: nil, token: oldUserToken)

        // .. to make sure worker's are not re-created for the same user
        XCTAssertEqual((client.backgroundWorkers.first as! TestWorker).id, oldWorkerUUID)
        XCTAssertEqual((client.backgroundWorkers.last as! TestEventWorker).id, oldEventWorkerUUID)
        
        // Generate userIds for second user
        let newUserId: UserId = .unique
        let newUserToken: Token = .unique
        
        // Set a user
        currentUserController.setUser(userId: newUserId, name: nil, imageURL: nil, token: newUserToken)

        // Check if the worker is re-created
        XCTAssertNotEqual((client.backgroundWorkers.first as! TestWorker).id, oldWorkerUUID)
        XCTAssertNotEqual((client.backgroundWorkers.last as! TestEventWorker).id, oldEventWorkerUUID)
    }
    
    // MARK: - Passive (not active) Client tests
    
    func test_passiveClient_doesNotHaveWorkers() {
        // Create Client with inactive flag set
        let client = ChatClient(config: inactiveInMemoryStorageConfig)
        
        // Assert that no background worker is initialized
        XCTAssert(client.backgroundWorkers.isEmpty)
    }
    
    func test_passiveClient_doesNotHaveWSClient() {
        // Create Client with inactive flag set
        let client = ChatClient(
            config: inactiveInMemoryStorageConfig
        )
        
        // Assert the wsClient is not initialized
        XCTAssertNil(client.webSocketClient)
        
        // Assert connection status is reported correctly
        XCTAssertEqual(
            client.connectionStatus,
            ConnectionStatus.disconnected(error: .ClientIsNotInActiveMode())
        )
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
    
    lazy var environment: _ChatClient<ExtraData>.Environment = { [unowned self] in
        .init(
            apiClientBuilder: {
                self.apiClient = APIClientMock(sessionConfiguration: $0, requestEncoder: $1, requestDecoder: $2)
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
                    shouldResetEphemeralValuesOnStart: $2
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
                self.notificationCenter = EventNotificationCenterMock(middlewares: $0)
                return self.notificationCenter!
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
            "stream-chat-swift-client-\(SystemEnvironment.version)"
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

class EventNotificationCenterMock: EventNotificationCenter {}
