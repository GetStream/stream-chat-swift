//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

extension ChatClient {
    static var mock: ChatClient {
        .init(
            config: .init(apiKey: .init(.unique)),
            workerBuilders: [],
            environment: .mock
        )
    }
    
    var mockAPIClient: APIClientMock {
        apiClient as! APIClientMock
    }
    
    var mockWebSocketClient: WebSocketClientMock {
        webSocketClient as! WebSocketClientMock
    }
    
    var mockDatabaseContainer: DatabaseContainerMock {
        databaseContainer as! DatabaseContainerMock
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

class ChatClientMock: ChatClient {
    @Atomic var init_config: ChatClientConfig
    @Atomic var init_tokenProvider: TokenProvider?
    @Atomic var init_workerBuilders: [WorkerBuilder]
    @Atomic var init_environment: Environment
    @Atomic var init_completion: ((Error?) -> Void)?

    @Atomic var fetchCurrentUserIdFromDatabase_called = false

    @Atomic var createBackgroundWorkers_called = false

    @Atomic var completeConnectionIdWaiters_called = false
    @Atomic var completeConnectionIdWaiters_connectionId: String?

    @Atomic var completeTokenWaiters_called = false
    @Atomic var completeTokenWaiters_token: Token?

    // MARK: - Overrides

    override init(
        config: ChatClientConfig,
        tokenProvider: TokenProvider? = nil,
        workerBuilders: [WorkerBuilder] = [],
        environment: Environment = .mock
    ) {
        init_config = config
        init_tokenProvider = tokenProvider
        init_workerBuilders = workerBuilders
        init_environment = environment

        super.init(
            config: config,
            tokenProvider: tokenProvider,
            workerBuilders: workerBuilders,
            environment: environment
        )
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
        (apiClient as? APIClientMock)?.cleanUp()

        fetchCurrentUserIdFromDatabase_called = false

        createBackgroundWorkers_called = false

        completeConnectionIdWaiters_called = false
        completeConnectionIdWaiters_connectionId = nil

        completeTokenWaiters_called = false
        completeTokenWaiters_token = nil
    }
}

extension ChatClient.Environment {
    static var mock: ChatClient.Environment {
        .init(
            apiClientBuilder: APIClientMock.init,
            webSocketClientBuilder: {
                WebSocketClientMock(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    eventDecoder: $2,
                    eventNotificationCenter: $3
                )
            },
            databaseContainerBuilder: {
                do {
                    return try DatabaseContainerMock(
                        kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
                        shouldFlushOnStart: $1,
                        shouldResetEphemeralValuesOnStart: $2,
                        localCachingSettings: $3,
                        deletedMessagesVisibility: $4,
                        shouldShowShadowedMessages: $5
                    )
                } catch {
                    XCTFail("Unable to initialize DatabaseContainerMock \(error)")
                    fatalError("Unable to initialize DatabaseContainerMock \(error)")
                }
            },
            requestEncoderBuilder: DefaultRequestEncoder.init,
            requestDecoderBuilder: DefaultRequestDecoder.init,
            eventDecoderBuilder: EventDecoder.init,
            notificationCenterBuilder: EventNotificationCenter.init,
            clientUpdaterBuilder: ChatClientUpdaterMock.init
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
