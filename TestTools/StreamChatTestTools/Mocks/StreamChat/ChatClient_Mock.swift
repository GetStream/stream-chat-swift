//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class ChatClient_Mock: ChatClient, @unchecked Sendable {
    @Atomic var init_config: ChatClientConfig
    @Atomic var init_environment: Environment
    @Atomic var init_completion: ((Error?) -> Void)?

    @Atomic var fetchCurrentUserIdFromDatabase_called = false

    @Atomic var createBackgroundWorkers_called = false

    @Atomic var completeConnectionIdWaiters_called = false
    @Atomic var completeConnectionIdWaiters_connectionId: String?

    @Atomic var completeTokenWaiters_called = false
    @Atomic var completeTokenWaiters_token: Token?

    var mockedAppSettings: AppSettings?

    override var appSettings: AppSettings? {
        mockedAppSettings
    }

    var mockedEventNotificationCenter: EventNotificationCenter_Mock? = nil

    override var eventNotificationCenter: EventNotificationCenter {
        mockedEventNotificationCenter ?? super.eventNotificationCenter
    }

    override var backgroundWorkers: [Worker] {
        _backgroundWorkers.isEmpty ? super.backgroundWorkers : _backgroundWorkers
    }
    
    func addBackgroundWorker(_ worker: Worker) {
        _backgroundWorkers.append(worker)
    }

    private var _backgroundWorkers = [Worker]()

    // MARK: - Overrides

    init(
        config: ChatClientConfig,
        workerBuilders: [WorkerBuilder] = [],
        environment: Environment = .mock
    ) {
        init_config = config
        init_environment = environment

        super.init(
            config: config,
            environment: environment,
            factory: ChatClientFactory(config: config, environment: environment)
        )
        if !workerBuilders.isEmpty {
            _backgroundWorkers = workerBuilders.map { $0(databaseContainer, apiClient) }
        }
    }
    
    override var currentUserId: UserId? {
        return currentUserId_mock
    }

    public var currentUserId_mock: UserId? {
        get {
            authenticationRepository.currentUserId
        }
        set {
            (authenticationRepository as? AuthenticationRepository_Mock)?.mockedCurrentUserId = newValue
        }
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

        _backgroundWorkers.removeAll()
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
    static func mock(config: ChatClientConfig? = nil, bundle: Bundle? = nil) -> ChatClient_Mock {
        .init(
            config: config ?? defaultMockedConfig,
            environment: .init(
                apiClientBuilder:  {
                    APIClient_Spy(
                        sessionConfiguration: $0,
                        requestEncoder: $1,
                        requestDecoder: $2,
                        attachmentDownloader: $3,
                        attachmentUploader: $4
                    )
                },
                webSocketClientBuilder: {
                    WebSocketClient_Mock(
                        sessionConfiguration: $0,
                        requestEncoder: $1,
                        eventDecoder: $2,
                        eventNotificationCenter: $3
                    )
                },
                databaseContainerBuilder: {
                    DatabaseContainer_Spy(
                        kind: $0,
                        bundle: bundle,
                        chatClientConfig: $1
                    )
                },
                internetConnection: { center, _ in
                    InternetConnection_Mock(notificationCenter: center)
                },
                authenticationRepositoryBuilder: {
                    AuthenticationRepository_Mock(
                        apiClient: $0,
                        databaseContainer: $1,
                        connectionRepository: $2,
                        tokenExpirationRetryStrategy: $3,
                        timerType: $4
                    )
                },
                syncRepositoryBuilder: {
                    SyncRepository_Mock(
                        config: $0,
                        offlineRequestsRepository: $1,
                        eventNotificationCenter: $2,
                        database: $3,
                        apiClient: $4,
                        channelListUpdater: $5
                    )
                },
                pollsRepositoryBuilder: {
                    PollsRepository_Mock(
                        database: $0,
                        apiClient: $1
                    )
                },
                draftMessagesRepositoryBuilder: {
                    DraftMessagesRepository_Mock(
                        database: $0,
                        apiClient: $1
                    )
                },
                channelListUpdaterBuilder: {
                    ChannelListUpdater_Spy(
                        database: $0,
                        apiClient: $1
                    )
                },
                messageRepositoryBuilder: {
                    MessageRepository_Mock(
                        database: $0,
                        apiClient: $1
                    )
                },
                offlineRequestsRepositoryBuilder: {
                    OfflineRequestsRepository_Mock(
                        messageRepository: $0,
                        database: $1,
                        apiClient: $2,
                        maxHoursThreshold: $3
                    )
                }
            )
        )
    }
}

extension ChatClient {
    static var mock: ChatClient_Mock {
        ChatClient_Mock(
            config: .init(apiKey: .init(.unique)),
            workerBuilders: [],
            environment: .mock
        )
    }

    var mockAPIClient: APIClient_Spy {
        apiClient as! APIClient_Spy
    }
    
    var mockChannelListUpdater: ChannelListUpdater_Spy {
        channelListUpdater as! ChannelListUpdater_Spy
    }

    var mockWebSocketClient: WebSocketClient_Mock {
        webSocketClient as! WebSocketClient_Mock
    }

    var mockDatabaseContainer: DatabaseContainer_Spy {
        databaseContainer as! DatabaseContainer_Spy
    }

    var mockSyncRepository: SyncRepository_Mock {
        syncRepository as! SyncRepository_Mock
    }

    var mockMessageRepository: MessageRepository_Mock {
        messageRepository as! MessageRepository_Mock
    }

    var mockOfflineRequestsRepository: OfflineRequestsRepository_Mock {
        offlineRequestsRepository as! OfflineRequestsRepository_Mock
    }

    var mockAuthenticationRepository: AuthenticationRepository_Mock {
        authenticationRepository as! AuthenticationRepository_Mock
    }
    
    var mockPollsRepository: PollsRepository_Mock {
        pollsRepository as! PollsRepository_Mock
    }

    var mockDraftMessagesRepository: DraftMessagesRepository_Mock {
        draftMessagesRepository as! DraftMessagesRepository_Mock
    }

    var mockRemindersRepository: RemindersRepository_Mock {
        remindersRepository as! RemindersRepository_Mock
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
            apiClientBuilder: {
                APIClient_Spy(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    requestDecoder: $2,
                    attachmentDownloader: $3,
                    attachmentUploader: $4
                )
            },
            webSocketClientBuilder: {
                WebSocketClient_Mock(
                    sessionConfiguration: $0,
                    requestEncoder: $1,
                    eventDecoder: $2,
                    eventNotificationCenter: $3
                )
            },
            databaseContainerBuilder: {
                DatabaseContainer_Spy(
                    kind: .inMemory,
                    chatClientConfig: $1
                )
            },
            requestEncoderBuilder: {
                DefaultRequestEncoder(baseURL: $0, apiKey: $1)
            },
            requestDecoderBuilder: {
                DefaultRequestDecoder()
            },
            eventDecoderBuilder: {
                EventDecoder()
            },
            notificationCenterBuilder: {
                EventNotificationCenter(database: $0)
            },
            authenticationRepositoryBuilder: {
                AuthenticationRepository_Mock(
                    apiClient: $0,
                    databaseContainer: $1,
                    connectionRepository: $2,
                    tokenExpirationRetryStrategy: $3,
                    timerType: $4
                )
            },
            syncRepositoryBuilder: {
                SyncRepository_Mock(
                    config: $0,
                    offlineRequestsRepository: $1,
                    eventNotificationCenter: $2,
                    database: $3,
                    apiClient: $4,
                    channelListUpdater: $5
                )
            },
            pollsRepositoryBuilder: {
                PollsRepository_Mock(
                    database: $0,
                    apiClient: $1
                )
            },
            draftMessagesRepositoryBuilder: {
                DraftMessagesRepository_Mock(
                    database: $0,
                    apiClient: $1
                )
            },
            remindersRepositoryBuilder: RemindersRepository_Mock.init,
            channelListUpdaterBuilder: {
                ChannelListUpdater_Spy(
                    database: $0,
                    apiClient: $1
                )
            },
            messageRepositoryBuilder: {
                MessageRepository_Mock(
                    database: $0,
                    apiClient: $1
                )
            },
            offlineRequestsRepositoryBuilder: {
                OfflineRequestsRepository_Mock(
                    messageRepository: $0,
                    database: $1,
                    apiClient: $2,
                    maxHoursThreshold: $3
                )
            }
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

extension ChatClient {
    convenience init(config: ChatClientConfig, environment: ChatClient.Environment) {
        self.init(
            config: config,
            environment: environment,
            factory: ChatClientFactory(config: config, environment: environment)
        )
    }
}

extension AppSettings {
    static func mock(
        name: String = "Stream iOS",
        fileUploadConfig: UploadConfig? = nil,
        imageUploadConfig: UploadConfig? = nil,
        autoTranslationEnabled: Bool = false,
        asyncUrlEnrichEnabled: Bool = false
    ) -> AppSettings {
        .init(
            name: name,
            fileUploadConfig: fileUploadConfig ?? .mock(),
            imageUploadConfig: imageUploadConfig ?? .mock(),
            autoTranslationEnabled: autoTranslationEnabled,
            asyncUrlEnrichEnabled: asyncUrlEnrichEnabled
        )
    }
}

extension AppSettings.UploadConfig {
    static func mock(
        allowedFileExtensions: [String] = [],
        blockedFileExtensions: [String] = [],
        allowedMimeTypes: [String] = [],
        blockedMimeTypes: [String] = [],
        sizeLimitInBytes: Int64? = nil
    ) -> AppSettings.UploadConfig {
        .init(
            allowedFileExtensions: allowedFileExtensions,
            blockedFileExtensions: blockedFileExtensions,
            allowedMimeTypes: allowedMimeTypes,
            blockedMimeTypes: blockedMimeTypes,
            sizeLimitInBytes: sizeLimitInBytes
        )
    }
}
