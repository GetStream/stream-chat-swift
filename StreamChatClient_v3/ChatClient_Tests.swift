//
// ChatClient_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChatClient_Tests: XCTestCase {
    var user: User!
    
    override func setUp() {
        super.setUp()
        user = User(id: UUID().uuidString)
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
        
        // Create a `Client` and assert that a DB file is created on the provided URL
        _ = ChatClient(currentUser: user, config: config, workerBuilders: [], environment: env)
            .persistentContainer
        
        XCTAssertEqual(usedDatabaseKind, .onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(user.id)))
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
        _ = ChatClient(currentUser: user, config: config, workerBuilders: [], environment: env)
            .persistentContainer
        
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
        
        // Create env object and store all `kind`s it's called with.
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
        _ = ChatClient(currentUser: user, config: config, workerBuilders: [], environment: env)
            .persistentContainer
        
        XCTAssertEqual(usedDatabaseKinds,
                       [.onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(user.id)), .inMemory])
    }
    
    // MARK: - WebSocketClient tests
    
    func test_webSocketClientIsInitialized() throws {
        // Use in-memory store
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
        config.baseURL = BaseURL(urlString: .unique)
        
        // Observe the parameters for WebSocketClient initialization
        var wsInitializationParameters: (urlRequest: URLRequest,
                                         sessionConfiguration: URLSessionConfiguration,
                                         eventDecoder: AnyEventDecoder,
                                         eventMiddlewares: [EventMiddleware])?
        
        var env = ChatClient.Environment()
        env.webSocketClientBuilder = {
            wsInitializationParameters = (urlRequest: $0, sessionConfiguration: $1, eventDecoder: $2, eventMiddlewares: $3)
            return WebSocketClientMock()
        }
        
        // Create a new chat client
        let client = ChatClient(currentUser: user,
                                config: config,
                                workerBuilders: [MessageSender.init],
                                environment: env)
        
        // Assert the init parameters are correct
        let parameters = try XCTUnwrap(wsInitializationParameters)
        let components = try XCTUnwrap(URLComponents(url: parameters.urlRequest.url!, resolvingAgainstBaseURL: false))
        
        XCTAssertEqual(components.scheme, "wss")
        XCTAssertEqual(components.host, config.baseURL.webSocketBaseURL.host)
        XCTAssertEqual(components.path, "/connect")
        XCTAssertNotNil(components.queryItems?["json"])
        
        assertMandatoryHeaderFields(parameters.sessionConfiguration, token: client.token)
        
        XCTAssert(wsInitializationParameters?.eventDecoder is EventDecoder<DefaultDataTypes>)
        
        XCTAssertEqual(wsInitializationParameters?.eventMiddlewares.count, 2)
        XCTAssert(wsInitializationParameters?.eventMiddlewares[0] is EventDataProcessorMiddleware<DefaultDataTypes>)
        XCTAssert(wsInitializationParameters?.eventMiddlewares[1] is HealthCheckFilter)
    }
    
    // MARK: - APIClient tests
    
    func test_apiClientIsInitialized() throws {
        // Use in-memory store
        var config = ChatClientConfig()
        config.isLocalStorageEnabled = false
        config.baseURL = BaseURL(urlString: .unique)
        
        // Observe the parameters for APIClient initialization
        var apiInitializationParameters: (apiKey: APIKey,
                                          baseURL: URL,
                                          sessionConfiguration: URLSessionConfiguration)?
        
        var apiClientMock: APIClientMock!
        var env = ChatClient.Environment()
        env.apiClientBuilder = {
            apiInitializationParameters = (apiKey: $0, baseURL: $1, sessionConfiguration: $2)
            apiClientMock = APIClientMock()
            return apiClientMock
        }
        
        // Create a new chat client
        let client = ChatClient(currentUser: user,
                                config: config,
                                workerBuilders: [MessageSender.init],
                                environment: env)
        
        // Assert the init parameters are correct
        let parameters = try XCTUnwrap(apiInitializationParameters)
        
        XCTAssertEqual(parameters.apiKey, config.apiKey)
        
        let components = try XCTUnwrap(URLComponents(url: parameters.baseURL, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, config.baseURL.restAPIBaseURL.host)
        
        assertMandatoryHeaderFields(parameters.sessionConfiguration, token: client.token)
        
        XCTAssertEqual(parameters.baseURL, config.baseURL.restAPIBaseURL)
        
        // Assert APIClient sets itself as WS connection state delegate
        XCTAssert(client.webSocketClient.connectionStateDelegate === apiClientMock)
    }
    
    // MARK: - Background workers tests
    
    func test_productionClientIsInitalizedWithAllMandatoryBackgroundWorkers() {
        // Create a new Client with production configuration
        let config = ChatClientConfig(apiKey: .init(.unique))
        let client = Client<DefaultDataTypes>(currentUser: user, config: config)
        
        // Check all the mandatory background workers are initialized
        XCTAssert(client.backgroundWorkers.contains { $0 is MessageSender })
        XCTAssert(client.backgroundWorkers.contains { $0 is ChannelEventsHandler<DefaultDataTypes> })
    }
    
    func test_backgroundWorkersAreInitialized() {
        // Set up mocks for APIClient, WSClient and Database
        let config = ChatClientConfig(apiKey: .init(.unique))
        var environment = Client<DefaultDataTypes>.Environment()
        environment.apiClientBuilder = { _, _, _ in APIClientMock() }
        environment.webSocketClientBuilder = { _, _, _, _ in WebSocketClientMock() }
        environment.databaseContainerBuilder = { _ in DatabaseContainerMock() }
        
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
        let client = Client(currentUser: user,
                            config: config,
                            workerBuilders: [TestWorker.init],
                            environment: environment)
        
        let testWorker = client.backgroundWorkers.first as? TestWorker
        XCTAssert(testWorker?.init_database is DatabaseContainerMock)
        XCTAssert(testWorker?.init_webSocketClient is WebSocketClientMock)
        XCTAssert(testWorker?.init_apiClient is APIClientMock)
    }
}

// MARK: - Local helpers

extension ChatClient_Tests {
    /// Asserts that URLSessionConfiguration contains all requier header fiedls
    private func assertMandatoryHeaderFields(_ config: URLSessionConfiguration, token: String) {
        let headers = config.httpAdditionalHeaders as? [String: String] ?? [:]
        XCTAssertEqual(headers["X-Stream-Client"], "stream-chat-swift-client-\(SystemEnvironment.version)")
        XCTAssertEqual(headers["X-Stream-Device"], SystemEnvironment.deviceModelName)
        XCTAssertEqual(headers["X-Stream-OS"], SystemEnvironment.systemName)
        XCTAssertEqual(headers["X-Stream-App-Environment"], SystemEnvironment.name)
        XCTAssertEqual(headers["Stream-Auth-Type"], "jwt") // TODO: CIS-164
        XCTAssertEqual(headers["Authorization"], token) // TODO: CIS-164
    }
}

private class DatabaseContainerMock: DatabaseContainer {
    init() {
        try! super.init(kind: .inMemory)
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
