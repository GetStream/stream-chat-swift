//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatClient {
    /// An object containing all dependencies of `Client`
    struct Environment: Sendable {
        var apiClientBuilder: @Sendable (
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ requestDecoder: RequestDecoder,
            _ attachmentDownloader: AttachmentDownloader,
            _ attachmentUploader: AttachmentUploader
        ) -> APIClient = {
            APIClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                requestDecoder: $2,
                attachmentDownloader: $3,
                attachmentUploader: $4
            )
        }

        var webSocketClientBuilder: (@Sendable (
            _ sessionConfiguration: URLSessionConfiguration,
            _ eventDecoder: AnyEventDecoder,
            _ notificationCenter: PersistentEventNotificationCenter
        ) -> WebSocketClient)? = {
            let wsEnvironment = WebSocketClient.Environment(eventBatchingPeriod: 0.5)
            return WebSocketClient(
                sessionConfiguration: $0,
                eventDecoder: $1,
                eventNotificationCenter: $2,
                webSocketClientType: .coordinator,
                environment: wsEnvironment,
                connectRequest: nil,
                healthCheckBeforeConnected: true
            )
        }

        var databaseContainerBuilder: @Sendable (
            _ kind: DatabaseContainer.Kind,
            _ chatClientConfig: ChatClientConfig
        ) -> DatabaseContainer = {
            DatabaseContainer(
                kind: $0,
                chatClientConfig: $1
            )
        }

        var reconnectionHandlerBuilder: @Sendable (_ chatClientConfig: ChatClientConfig) -> StreamTimer? = {
            guard let reconnectionTimeout = $0.reconnectionTimeout else { return nil }
            return ScheduledStreamTimer(interval: reconnectionTimeout, fireOnStart: false, repeats: false)
        }

        var requestEncoderBuilder: @Sendable (_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = { DefaultRequestEncoder(baseURL: $0, apiKey: $1) }
        var requestDecoderBuilder: @Sendable () -> RequestDecoder = { DefaultRequestDecoder() }

        var eventDecoderBuilder: @Sendable () -> EventDecoder = { EventDecoder() }

        var notificationCenterBuilder: @Sendable (_ database: DatabaseContainer, _ manualEventHandler: ManualEventHandler?) -> PersistentEventNotificationCenter = { PersistentEventNotificationCenter(database: $0, manualEventHandler: $1) }

        var internetConnection: @Sendable (_ center: NotificationCenter, _ monitor: InternetConnectionMonitor) -> InternetConnection = {
            InternetConnection(notificationCenter: $0, monitor: $1)
        }

        var internetMonitor: InternetConnectionMonitor {
            if let monitor = monitor {
                return monitor
            } else {
                return InternetConnection.Monitor()
            }
        }

        var monitor: InternetConnectionMonitor?

        var connectionRepositoryBuilder: @Sendable (
            _ isClientInActiveMode: Bool,
            _ syncRepository: SyncRepository,
            _ webSocketEncoder: RequestEncoder?,
            _ webSocketClient: WebSocketClient?,
            _ apiClient: APIClient,
            _ timerType: TimerScheduling.Type
        ) -> ConnectionRepository = {
            ConnectionRepository(
                isClientInActiveMode: $0,
                syncRepository: $1,
                webSocketEncoder: $2,
                webSocketClient: $3,
                apiClient: $4,
                timerType: $5
            )
        }

        var backgroundTaskSchedulerBuilder: @Sendable () -> BackgroundTaskScheduler? = {
            if Bundle.main.isAppExtension {
                // No background task scheduler exists for app extensions.
                return nil
            } else {
                #if os(iOS)
                return IOSBackgroundTaskScheduler()
                #else
                // No need for background schedulers on macOS, app continues running when inactive.
                return nil
                #endif
            }
        }

        var timerType: TimerScheduling.Type = DefaultTimer.self

        var tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy()

        var connectionRecoveryHandlerBuilder: @Sendable (
            _ webSocketClient: WebSocketClient,
            _ eventNotificationCenter: EventNotificationCenter,
            _ backgroundTaskScheduler: BackgroundTaskScheduler?,
            _ internetConnection: InternetConnection,
            _ keepConnectionAliveInBackground: Bool
        ) -> ConnectionRecoveryHandler = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                backgroundTaskScheduler: $2,
                internetConnection: $3,
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: DefaultTimer.self,
                keepConnectionAliveInBackground: $4
            )
        }

        var authenticationRepositoryBuilder: @Sendable (
            _ apiClient: APIClient,
            _ databaseContainer: DatabaseContainer,
            _ connectionRepository: ConnectionRepository,
            _ tokenExpirationRetryStrategy: RetryStrategy,
            _ timerType: TimerScheduling.Type
        ) -> AuthenticationRepository = {
            AuthenticationRepository(
                apiClient: $0,
                databaseContainer: $1,
                connectionRepository: $2,
                tokenExpirationRetryStrategy: $3,
                timerType: $4
            )
        }

        var syncRepositoryBuilder: @Sendable (
            _ config: ChatClientConfig,
            _ offlineRequestsRepository: OfflineRequestsRepository,
            _ eventNotificationCenter: EventNotificationCenter,
            _ database: DatabaseContainer,
            _ apiClient: APIClient,
            _ channelListUpater: ChannelListUpdater
        ) -> SyncRepository = {
            SyncRepository(
                config: $0,
                offlineRequestsRepository: $1,
                eventNotificationCenter: $2,
                database: $3,
                apiClient: $4,
                channelListUpdater: $5
            )
        }

        var channelRepositoryBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelRepository = {
            ChannelRepository(database: $0, apiClient: $1)
        }
        
        var pollsRepositoryBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> PollsRepository = {
            PollsRepository(database: $0, apiClient: $1)
        }

        var draftMessagesRepositoryBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> DraftMessagesRepository = {
            DraftMessagesRepository(database: $0, apiClient: $1)
        }

        var remindersRepositoryBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> RemindersRepository = {
            RemindersRepository(database: $0, apiClient: $1)
        }
        
        var channelListUpdaterBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = {
            ChannelListUpdater(database: $0, apiClient: $1)
        }

        var messageRepositoryBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageRepository = {
            MessageRepository(database: $0, apiClient: $1)
        }

        var offlineRequestsRepositoryBuilder: @Sendable (
            _ messageRepository: MessageRepository,
            _ database: DatabaseContainer,
            _ apiClient: APIClient,
            _ maxHoursThreshold: Int
        ) -> OfflineRequestsRepository = {
            OfflineRequestsRepository(
                messageRepository: $0,
                database: $1,
                apiClient: $2,
                maxHoursThreshold: $3
            )
        }
    }
}
