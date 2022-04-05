//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class ChatClient_Mock: ChatClient {
    @Atomic var init_config: ChatClientConfig
    @Atomic var init_tokenProvider: TokenProvider?
    @Atomic var init_environment: Environment
    @Atomic var init_completion: ((Error?) -> Void)?

    @Atomic var fetchCurrentUserIdFromDatabase_called = false

    @Atomic var createBackgroundWorkers_called = false

    @Atomic var completeConnectionIdWaiters_called = false
    @Atomic var completeConnectionIdWaiters_connectionId: String?

    @Atomic var completeTokenWaiters_called = false
    @Atomic var completeTokenWaiters_token: Token?

    override var backgroundWorkers: [Worker] {
        _backgroundWorkers ?? super.backgroundWorkers
    }

    private var _backgroundWorkers: [Worker]?

    // MARK: - Overrides

    init(
        config: ChatClientConfig,
        tokenProvider: TokenProvider? = nil,
        workerBuilders: [WorkerBuilder] = [],
        environment: Environment = .mock
    ) {
        init_config = config
        init_tokenProvider = tokenProvider
        init_environment = environment

        super.init(
            config: config,
            tokenProvider: tokenProvider,
            environment: environment
        )
        if !workerBuilders.isEmpty {
            _backgroundWorkers = workerBuilders.map { $0(databaseContainer, apiClient) }
        }
    }

    override func fetchCurrentUserIdFromDatabase() -> UserId? {
        fetchCurrentUserIdFromDatabase_called = true

        return super.fetchCurrentUserIdFromDatabase()
    }

    override func createBackgroundWorkers() {
        createBackgroundWorkers_called = true

        super.createBackgroundWorkers()
    }

    override func completeConnectionIdWaiters(connectionId: String?) {
        completeConnectionIdWaiters_called = true
        completeConnectionIdWaiters_connectionId = connectionId

        super.completeConnectionIdWaiters(connectionId: connectionId)
    }

    override func completeTokenWaiters(token: Token?) {
        completeTokenWaiters_called = true
        completeTokenWaiters_token = token

        super.completeTokenWaiters(token: token)
    }

    // MARK: - Clean Up

    func cleanUp() {
        (apiClient as? APIClient_Spy)?.cleanUp()

        fetchCurrentUserIdFromDatabase_called = false

        createBackgroundWorkers_called = false

        completeConnectionIdWaiters_called = false
        completeConnectionIdWaiters_connectionId = nil

        completeTokenWaiters_called = false
        completeTokenWaiters_token = nil

        _backgroundWorkers?.removeAll()
        init_tokenProvider = nil
        init_completion = nil
    }
}

extension ChatClient {
    static var defaultMockedConfig: ChatClientConfig {
        var config = ChatClientConfig(apiKey: .init("--== Mock ChatClient ==--"))
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false
        return config
    }

    /// Create a new instance of mock `ChatClient`
    static func mock(config: ChatClientConfig? = nil) -> ChatClient {
        .init(
            config: config ?? defaultMockedConfig,
            environment: .init(
                apiClientBuilder: APIClient_Spy.init,
                webSocketClientBuilder: {
                    WebSocketClient_Mock(
                        sessionConfiguration: $0,
                        requestEncoder: $1,
                        eventDecoder: $2,
                        eventNotificationCenter: $3
                    )
                },
                databaseContainerBuilder: {
                    try DatabaseContainer_Spy(
                        kind: $0,
                        shouldFlushOnStart: $1,
                        shouldResetEphemeralValuesOnStart: $2,
                        localCachingSettings: $3,
                        deletedMessagesVisibility: $4,
                        shouldShowShadowedMessages: $5
                    )
                }
            )
        )
    }
}

extension ChatClient {
    static var mock: ChatClient {
        ChatClient_Mock(
            config: .init(apiKey: .init(.unique)),
            workerBuilders: [],
            environment: .mock
        )
    }
    
    var mockAPIClient: APIClient_Spy {
        apiClient as! APIClient_Spy
    }
    
    var mockWebSocketClient: WebSocketClient_Mock {
        webSocketClient as! WebSocketClient_Mock
    }
    
    var mockDatabaseContainer: DatabaseContainer_Spy {
        databaseContainer as! DatabaseContainer_Spy
    }

    func simulateProvidedConnectionId(connectionId: ConnectionId?) {
        guard let connectionId = connectionId else {
            webSocketClient(
                mockWebSocketClient,
                didUpdateConnectionState: .disconnected(source: .serverInitiated(error: nil))
            )
            return
        }
        webSocketClient(mockWebSocketClient, didUpdateConnectionState: .connected(connectionId: connectionId))
    }
}

extension ChatClient.Environment {
    static var mock: ChatClient.Environment {
        .init(
            apiClientBuilder: APIClient_Spy.init,
            webSocketClientBuilder: {
                WebSocketClient_Mock(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    eventDecoder: $2,
                    eventNotificationCenter: $3
                )
            },
            databaseContainerBuilder: {
                do {
                    return try DatabaseContainer_Spy(
                        kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
                        shouldFlushOnStart: $1,
                        shouldResetEphemeralValuesOnStart: $2,
                        localCachingSettings: $3,
                        deletedMessagesVisibility: $4,
                        shouldShowShadowedMessages: $5
                    )
                } catch {
                    XCTFail("Unable to initialize DatabaseContainer_Spy \(error)")
                    fatalError("Unable to initialize DatabaseContainer_Spy \(error)")
                }
            },
            requestEncoderBuilder: DefaultRequestEncoder.init,
            requestDecoderBuilder: DefaultRequestDecoder.init,
            eventDecoderBuilder: EventDecoder.init,
            notificationCenterBuilder: EventNotificationCenter.init,
            clientUpdaterBuilder: ChatClientUpdater_Mock.init
        )
    }

    static var withZeroEventBatchingPeriod: Self {
        .init(
            webSocketClientBuilder: {
                var webSocketEnvironment = WebSocketClient.Environment()
                webSocketEnvironment.eventBatcherBuilder = {
                    Batcher<Event>(period: 0, handler: $0)
                }
                
                return WebSocketClient(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    eventDecoder: $2,
                    eventNotificationCenter: $3,
                    environment: webSocketEnvironment
                )
            }
        )
    }
}
