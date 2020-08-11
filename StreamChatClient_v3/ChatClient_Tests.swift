//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChatClient_Tests: StressTestCase {
    var userId: UserId!
    private var testEnv: TestEnvironment<DefaultDataTypes>!
    
    // A helper providing ChatClientConfic with in-memory DB option
    var inMemoryStorageConfig: ChatClientConfig {
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
        config.baseURL = BaseURL(urlString: .unique)
        return config
    }
    
    override func setUp() {
        super.setUp()
        userId = .unique
        testEnv = .init()
    }
    
    override func tearDown() {
        weak var weak_testEnv = testEnv
        testEnv = nil
        XCTAssertNil(weak_testEnv)
        
        super.tearDown()
    }
    
    // MARK: - Database stack tests
    
    func test_clientDatabaseStackInitialization_whenLocalStorageEnabled_respectsConfigValues() {
        // Prepare a config with the local storage
        let storeFolderURL = URL.newTemporaryDirectoryURL()
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = true
        config.localStorageFolderURL = storeFolderURL
        
        var usedDatabaseKind: DatabaseContainer.Kind?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { kind in
            usedDatabaseKind = kind
            return DatabaseContainerMock()
        }
        
        // Create a `Client` and assert that a DB file is created on the provided URL + APIKey path
        _ = ChatClient(config: config, workerBuilders: [Worker.init], environment: env)
        XCTAssertEqual(usedDatabaseKind,
                       .onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString)))
    }
    
    func test_clientDatabaseStackInitialization_whenLocalStorageDisabled() {
        // Prepare a config with the in-memory storage
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
        
        var usedDatabaseKind: DatabaseContainer.Kind?
        
        // Create env object with custom database builder
        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { kind in
            usedDatabaseKind = kind
            return DatabaseContainerMock()
        }
        
        // Create a `Client` and assert the correct DB kind is used
        _ = ChatClient(config: config, workerBuilders: [Worker.init], environment: env)
        
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
        var errorsToReturn = Queue(TestError())
        
        // Create env object and store all `kinds it's called with.
        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { kind in
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
        _ = ChatClient(config: config, workerBuilders: [Worker.init], environment: env)
        
        XCTAssertEqual(usedDatabaseKinds,
                       [.onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(config.apiKey.apiKeyString)), .inMemory])
    }
    
    // MARK: - WebSocketClient tests
    
    func test_webSocketClientIsInitialized() throws {
        // Use in-memory store
        // Create a new chat client
        let client = ChatClient(config: inMemoryStorageConfig,
                                workerBuilders: [MessageSender.init],
                                environment: testEnv.environment)
        
        // Assert the init parameters are correct
        let webSocket = testEnv.webSocketClient
        assertMandatoryHeaderFields(webSocket?.init_sessionConfiguration)
        XCTAssert(webSocket?.init_requestEncoder is TestRequestEncoder)
        XCTAssertNotNil(webSocket?.init_eventDecoder)
        
        // EventDataProcessorMiddleware must be always first
        XCTAssert(webSocket?.init_eventMiddlewares[0] is EventDataProcessorMiddleware<DefaultDataTypes>)
        
        // Assert Client sets itself as delegate for the request encoder
        XCTAssert(webSocket?.init_requestEncoder.connectionDetailsProviderDelegate === client)
    }
    
    // MARK: - ConnectionDetailsProvider tests
    
    func test_clientProvidesConnectionId() throws {
        // Create a new chat client
        let client = ChatClient(config: inMemoryStorageConfig,
                                workerBuilders: [MessageSender.init],
                                environment: testEnv.environment)
        
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
    
    func test_clientProvidesToken() throws {
        // Create a new chat client
        let client = ChatClient(config: inMemoryStorageConfig,
                                workerBuilders: [MessageSender.init],
                                environment: testEnv.environment)
        
        // Assert the token of anonymous user is `nil`
        XCTAssertNil(client.provideToken())
        
        // Set a new user
        let newToken: Token = .unique
        client.setUser(userId: .unique, token: newToken)
        
        AssertAsync.willBeEqual(client.provideToken(), newToken)
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
        let client = ChatClient(config: config,
                                workerBuilders: [MessageSender.init],
                                environment: testEnv.environment)
        
        // Assert the token of anonymous user is `nil`
        XCTAssertNil(client.provideToken())
        
        // Set a new user without an explicit token
        client.setUser(userId: newUserId)
        
        AssertAsync.willBeEqual(client.provideToken(), newToken)
    }
    
    // MARK: - APIClient tests
    
    func test_apiClientIsInitialized() throws {
        // Create a new chat client
        _ = ChatClient(config: inMemoryStorageConfig,
                       workerBuilders: [MessageSender.init],
                       environment: testEnv.environment)
        
        assertMandatoryHeaderFields(testEnv.apiClient?.init_sessionConfiguration)
        XCTAssert(testEnv.apiClient?.init_requestDecoder is TestRequestDecoder)
        XCTAssert(testEnv.apiClient?.init_requestEncoder is TestRequestEncoder)
    }
    
    // MARK: - Background workers tests
    
    func test_productionClientIsInitalizedWithAllMandatoryBackgroundWorkers() {
        // Create a new Client with production configuration
        let config = ChatClientConfig(apiKey: .init(.unique))
        let client = Client<DefaultDataTypes>(config: config)
        
        // Check all the mandatory background workers are initialized
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageSender })
    }
    
    func test_backgroundWorkersAreInitialized() {
        // Set up mocks for APIClient, WSClient and Database
        let config = ChatClientConfig(apiKey: .init(.unique))
        
        // Prepare a test worker
        class TestWorker: Worker {
            var init_database: DatabaseContainer?
            var init_webSocketClient: WebSocketClient?
            var init_apiClient: APIClient?
            
            override init(database: DatabaseContainer, webSocketClient: WebSocketClient, apiClient: APIClient) {
                init_database = database
                init_webSocketClient = webSocketClient
                init_apiClient = apiClient
                
                super.init(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
            }
        }
        
        // Create a Client instance and check the TestWorker is initialized properly
        let client = Client(config: config,
                            workerBuilders: [TestWorker.init],
                            environment: testEnv.environment)
        
        let testWorker = client.backgroundWorkers.first as? TestWorker
        XCTAssert(testWorker?.init_database is DatabaseContainerMock)
        XCTAssert(testWorker?.init_webSocketClient is WebSocketClientMock)
        XCTAssert(testWorker?.init_apiClient is APIClientMock)
    }
    
    // MARK: - Setting a new current user tests
    
    func test_defaultUserIsAnonymous() {
        let client = ChatClient(config: inMemoryStorageConfig)
        
        // The current userId should be set, but the user is not loaded before the connection is established
        XCTAssertTrue(client.currentUserId.isAnonymousUser)
        XCTAssertNil(client.currentUser)
    }
    
    func test_settingAnonymousUser() {
        let client = Client(config: inMemoryStorageConfig, workerBuilders: [MessageSender.init], environment: testEnv.environment)
        assert(testEnv.webSocketClient!.connect_calledCounter == 0)
        
        let oldUserId = client.currentUserId
        let oldWSConnectEndpoint = client.webSocketClient.connectEndpoint
        
        // Set up a new anonymous user
        var setUserCompletionCalled = false
        client.setAnonymousUser(completion: { _ in setUserCompletionCalled = true })
        
        AssertAsync {
            // New user id is set
            Assert.willBeTrue(client.currentUserId != oldUserId)
            
            // Database should be flushed
            Assert.willBeTrue(self.testEnv.databaseContainer?.flush_called == true)
            
            // WebSocketClient connect endpoint is updated
            Assert.willBeTrue(AnyEndpoint(oldWSConnectEndpoint) != AnyEndpoint(client.webSocketClient.connectEndpoint))
            
            // WebSocketClient connect is called
            Assert.willBeEqual(self.testEnv.webSocketClient?.connect_calledCounter, 1)
        }
        
        // Make sure the completion is not called yet
        XCTAssertFalse(setUserCompletionCalled)
        
        // Simulate successful connection
        testEnv.webSocketClient!.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!,
                             didUpdateConectionState: .connected(connectionId: .unique))
        
        // Check the completion is called
        AssertAsync.willBeTrue(setUserCompletionCalled)
    }
    
    func test_settingUser() {
        let client = Client(config: inMemoryStorageConfig, workerBuilders: [MessageSender.init], environment: testEnv.environment)
        assert(testEnv.webSocketClient!.connect_calledCounter == 0)
        
        let oldWSConnectEndpoint = client.webSocketClient.connectEndpoint
        
        let newUserId: UserId = .unique
        let newUserToken: Token = .unique
        
        // Set up a new user
        var setUserCompletionCalled = false
        client.setUser(userId: newUserId, token: newUserToken, completion: { _ in setUserCompletionCalled = true })
        
        AssertAsync {
            // New user id is set
            Assert.willBeEqual(client.currentUserId, newUserId)
            
            // Database should be flushed
            Assert.willBeTrue(self.testEnv.databaseContainer?.flush_called == true)
            
            // WebSocketClient connect endpoint is updated
            Assert.willBeTrue(AnyEndpoint(oldWSConnectEndpoint) != AnyEndpoint(client.webSocketClient.connectEndpoint))
            
            // WebSocketClient connect is called
            Assert.willBeEqual(self.testEnv.webSocketClient?.connect_calledCounter, 1)
        }
        
        // Make sure the completion is not called yet
        XCTAssertFalse(setUserCompletionCalled)
        
        // Simulate a health check event with the current user data
        // This should trigger the middlewares and save the current user data to DB
        testEnv.webSocketClient?.websocketDidReceiveMessage(healthCheckEventJSON(userId: newUserId))
        
        // Simulate successful connection
        testEnv.webSocketClient!.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!,
                             didUpdateConectionState: .connected(connectionId: .unique))
        
        // Check the completion is called and the current user model is available
        AssertAsync {
            // Completion is called
            Assert.willBeTrue(setUserCompletionCalled)
            
            // Current user data are available
            Assert.willBeEqual(client.currentUser?.id, newUserId)
            
            // The token is updated
            Assert.willBeEqual(client.provideToken(), newUserToken)
        }
    }
    
    func test_disconnectAndConnect() {
        // Set up a new anonymous user
        let client = Client(config: inMemoryStorageConfig, workerBuilders: [MessageSender.init], environment: testEnv.environment)
        
        // Set up a new anonymous user and wait for completion
        var setUserCompletionCalled = false
        client.setAnonymousUser(completion: { _ in setUserCompletionCalled = true })
        
        // Simulate successful connection
        testEnv.webSocketClient!.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!,
                             didUpdateConectionState: .connected(connectionId: .unique))
        
        // Wait for the connection to succeed
        AssertAsync.willBeTrue(setUserCompletionCalled)
        
        // Reset the call counters
        testEnv.webSocketClient?.connect_calledCounter = 0
        testEnv.webSocketClient?.disconnect_calledCounter = 0
        
        // Disconnect and assert WS is disconnected
        client.disconnect()
        XCTAssertEqual(testEnv.webSocketClient?.disconnect_calledCounter, 1)
        
        // Simulate WS disconnecting
        testEnv.webSocketClient!.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!, didUpdateConectionState: .notConnected(error: nil))
        
        // Call connect again and assert WS connect is called
        var connectCompletionCalled = false
        client.connect(completion: { _ in connectCompletionCalled = true })
        XCTAssertEqual(testEnv.webSocketClient!.connect_calledCounter, 1)
        
        // Simulate successful connection
        testEnv.webSocketClient!.connectionStateDelegate?
            .webSocketClient(testEnv.webSocketClient!,
                             didUpdateConectionState: .connected(connectionId: .unique))
        
        AssertAsync {
            Assert.willBeTrue(connectCompletionCalled)
        }
    }
}

/// A helper class which provides mock environment for Client.
private class TestEnvironment<ExtraData: ExtraDataTypes> {
    var apiClient: APIClientMock?
    var webSocketClient: WebSocketClientMock?
    var databaseContainer: DatabaseContainerMock?
    
    var requestEncoder: TestRequestEncoder?
    var requestDecoder: TestRequestDecoder?
    
    var eventDecoder: EventDecoder<ExtraData>?
    
    lazy var environment: Client<ExtraData>.Environment = { [unowned self] in
        .init(apiClientBuilder: {
            self.apiClient = APIClientMock(sessionConfiguration: $0, requestEncoder: $1, requestDecoder: $2)
            return self.apiClient!
        },
              webSocketClientBuilder: {
            self.webSocketClient = WebSocketClientMock(connectEndpoint: $0,
                                                       sessionConfiguration: $1,
                                                       requestEncoder: $2,
                                                       eventDecoder: $3,
                                                       eventMiddlewares: $4)
            return self.webSocketClient!
        },
              databaseContainerBuilder: {
            self.databaseContainer = try! DatabaseContainerMock(kind: $0)
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
    })
    }()
}

// MARK: - Local helpers

private func healthCheckEventJSON(userId: UserId) -> String {
    """
    {
        "created_at" : "2020-07-10T11:44:29.190502105Z",
        "me" : {
            "language" : "",
            "totalUnreadCount" : 0,
            "unread_count" : 0,
            "image" : "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall",
            "updated_at" : "2020-07-10T11:44:29.179977Z",
            "unreadChannels" : 0,
            "total_unread_count" : 0,
            "mutes" : [],
            "unread_channels" : 0,
            "devices" : [],
            "name" : "broken-waterfall-5",
            "last_active" : "2020-07-10T11:44:29.185810874Z",
            "banned" : false,
            "id" : "\(userId)",
            "roles" : [],
            "extraData" : {
                "name" : "Tester"
            },
            "role" : "user",
            "created_at" : "2019-12-12T15:33:46.488935Z",
            "channel_mutes" : [],
            "online" : true,
            "invisible" : false
        },
        "type" : "health.check",
        "connection_id" : "d94b53fa-ddd4-4413-8dda-8da33cabedd9",
        "cid" : "*"
    }
    """
}

extension ChatClient_Tests {
    /// Asserts that URLSessionConfiguration contains all require header fields
    private func assertMandatoryHeaderFields(_ config: URLSessionConfiguration?,
                                             file: StaticString = #file,
                                             line: UInt = #line) {
        guard let config = config else {
            XCTFail("Config is `nil`", file: file, line: line)
            return
        }
        
        let headers = config.httpAdditionalHeaders as? [String: String] ?? [:]
        XCTAssertEqual(headers["X-Stream-Client"], "stream-chat-swift-client-\(SystemEnvironment.version)"
            + "|\(SystemEnvironment.deviceModelName)"
            + "|\(SystemEnvironment.systemName)"
            + "|\(SystemEnvironment.name)")
    }
}

class DatabaseContainerMock: DatabaseContainer {
    var init_kind: DatabaseContainer.Kind
    var flush_called = false
    
    convenience init() {
        try! self.init(kind: .inMemory)
    }
    
    override init(kind: DatabaseContainer.Kind, modelName: String = "StreamChatModel", bundle: Bundle? = nil) throws {
        init_kind = kind
        try super.init(kind: kind, modelName: modelName, bundle: bundle)
    }
    
    override func removeAllData(force: Bool, completion: ((Error?) -> Void)? = nil) {
        flush_called = true
        super.removeAllData(force: force, completion: completion)
    }
}

private struct Queue<Element> {
    init(_ elements: Element...) {
        storage = elements
    }
    
    private var storage = [Element]()
    mutating func push(_ element: Element) {
        storage.append(element)
    }
    
    mutating func pop() -> Element? {
        let first = storage.first
        storage = Array(storage.dropFirst())
        return first
    }
}

private extension ChatClientConfig {
    init() {
        self = .init(apiKey: APIKey(.unique))
    }
}

// MARK: - Mock

class WebSocketClientMock: WebSocketClient {
    let init_connectEndpoint: Endpoint<EmptyResponse>
    let init_sessionConfiguration: URLSessionConfiguration
    let init_requestEncoder: RequestEncoder
    let init_eventDecoder: AnyEventDecoder
    let init_eventMiddlewares: [EventMiddleware]
    let init_reconnectionStrategy: WebSocketClientReconnectionStrategy
    let init_environment: WebSocketClient.Environment
    
    var connect_calledCounter = 0
    var disconnect_calledCounter = 0
    
    override init(
        connectEndpoint: Endpoint<EmptyResponse>,
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        eventDecoder: AnyEventDecoder,
        eventMiddlewares: [EventMiddleware],
        reconnectionStrategy: WebSocketClientReconnectionStrategy = DefaultReconnectionStrategy(),
        environment: WebSocketClient.Environment = .init()
    ) {
        init_connectEndpoint = connectEndpoint
        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_eventDecoder = eventDecoder
        init_eventMiddlewares = eventMiddlewares
        init_reconnectionStrategy = reconnectionStrategy
        init_environment = environment
        
        super.init(connectEndpoint: connectEndpoint, sessionConfiguration: sessionConfiguration, requestEncoder: requestEncoder,
                   eventDecoder: eventDecoder, eventMiddlewares: eventMiddlewares, reconnectionStrategy: reconnectionStrategy,
                   environment: environment)
    }
    
    override func connect() {
        connect_calledCounter += 1
    }
    
    override func disconnect(source: ConnectionState.DisconnectionSource = .userInitiated) {
        disconnect_calledCounter += 1
    }
}

extension WebSocketClientMock {
    convenience init() {
        self.init(connectEndpoint: .init(path: "", method: .get, queryItems: nil, requiresConnectionId: false, body: nil),
                  sessionConfiguration: .default,
                  requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
                  eventDecoder: EventDecoder<DefaultDataTypes>(),
                  eventMiddlewares: [])
    }
}
