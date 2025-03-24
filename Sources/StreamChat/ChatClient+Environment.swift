//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatClient {
    /// An object containing all dependencies of `Client`
    struct Environment: Sendable {
        var apiClientBuilder: @Sendable(
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ requestDecoder: RequestDecoder,
            _ attachmentDownloader: AttachmentDownloader,
            _ attachmentUploader: AttachmentUploader
        ) -> APIClient = APIClient.init

        var webSocketClientBuilder: (@Sendable(
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ eventDecoder: AnyEventDecoder,
            _ notificationCenter: EventNotificationCenter
        ) -> WebSocketClient)? = {
            WebSocketClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                eventDecoder: $2,
                eventNotificationCenter: $3
            )
        }

        var databaseContainerBuilder: @Sendable(
            _ kind: DatabaseContainer.Kind,
            _ chatClientConfig: ChatClientConfig
        ) -> DatabaseContainer = {
            DatabaseContainer(
                kind: $0,
                chatClientConfig: $1
            )
        }

        var reconnectionHandlerBuilder: @Sendable(_ chatClientConfig: ChatClientConfig) -> StreamTimer? = {
            guard let reconnectionTimeout = $0.reconnectionTimeout else { return nil }
            return ScheduledStreamTimer(interval: reconnectionTimeout, fireOnStart: false, repeats: false)
        }

        var requestEncoderBuilder: @Sendable(_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = DefaultRequestEncoder.init
        var requestDecoderBuilder: @Sendable() -> RequestDecoder = DefaultRequestDecoder.init

        var eventDecoderBuilder: @Sendable() -> EventDecoder = EventDecoder.init

        var notificationCenterBuilder = EventNotificationCenter.init

        var internetConnection: @Sendable(_ center: NotificationCenter, _ monitor: InternetConnectionMonitor) -> InternetConnection = {
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

        var connectionRepositoryBuilder = ConnectionRepository.init

        var backgroundTaskSchedulerBuilder: @Sendable() -> BackgroundTaskScheduler? = {
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

        var timerType: Timer.Type = DefaultTimer.self

        var tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy()

        var connectionRecoveryHandlerBuilder: @Sendable(
            _ webSocketClient: WebSocketClient,
            _ eventNotificationCenter: EventNotificationCenter,
            _ syncRepository: SyncRepository,
            _ backgroundTaskScheduler: BackgroundTaskScheduler?,
            _ internetConnection: InternetConnection,
            _ keepConnectionAliveInBackground: Bool
        ) -> ConnectionRecoveryHandler = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                syncRepository: $2,
                backgroundTaskScheduler: $3,
                internetConnection: $4,
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: DefaultTimer.self,
                keepConnectionAliveInBackground: $5
            )
        }

        var authenticationRepositoryBuilder = AuthenticationRepository.init

        var syncRepositoryBuilder: @Sendable(
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

        var channelRepositoryBuilder: @Sendable(
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelRepository = {
            ChannelRepository(database: $0, apiClient: $1)
        }
        
        var pollsRepositoryBuilder: @Sendable(
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> PollsRepository = {
            PollsRepository(database: $0, apiClient: $1)
        }

        var draftMessagesRepositoryBuilder: @Sendable(
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> DraftMessagesRepository = {
            DraftMessagesRepository(database: $0, apiClient: $1)
        }

        var channelListUpdaterBuilder: @Sendable(
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = {
            ChannelListUpdater(database: $0, apiClient: $1)
        }

        var messageRepositoryBuilder: @Sendable(
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageRepository = {
            MessageRepository(database: $0, apiClient: $1)
        }

        var offlineRequestsRepositoryBuilder: @Sendable(
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
