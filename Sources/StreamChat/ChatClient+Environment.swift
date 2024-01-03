//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatClient {
    /// An object containing all dependencies of `Client`
    struct Environment {
        var apiClientBuilder: (
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ requestDecoder: RequestDecoder,
            _ attachmentUploader: AttachmentUploader
        ) -> APIClient = {
            APIClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                requestDecoder: $2,
                attachmentUploader: $3
            )
        }

        var webSocketClientBuilder: ((
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

        var databaseContainerBuilder: (
            _ kind: DatabaseContainer.Kind,
            _ shouldFlushOnStart: Bool,
            _ shouldResetEphemeralValuesOnStart: Bool,
            _ localCachingSettings: ChatClientConfig.LocalCaching?,
            _ deletedMessageVisibility: ChatClientConfig.DeletedMessageVisibility?,
            _ shouldShowShadowedMessages: Bool?
        ) -> DatabaseContainer = {
            DatabaseContainer(
                kind: $0,
                shouldFlushOnStart: $1,
                shouldResetEphemeralValuesOnStart: $2,
                localCachingSettings: $3,
                deletedMessagesVisibility: $4,
                shouldShowShadowedMessages: $5
            )
        }

        var extensionLifecycleBuilder = NotificationExtensionLifecycle.init

        var requestEncoderBuilder: (_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = DefaultRequestEncoder.init
        var requestDecoderBuilder: () -> RequestDecoder = DefaultRequestDecoder.init

        var eventDecoderBuilder: () -> EventDecoder = EventDecoder.init

        var notificationCenterBuilder = EventNotificationCenter.init

        var internetConnection: (_ center: NotificationCenter, _ monitor: InternetConnectionMonitor) -> InternetConnection = {
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

        var backgroundTaskSchedulerBuilder: () -> BackgroundTaskScheduler? = {
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

        var connectionRecoveryHandlerBuilder: (
            _ webSocketClient: WebSocketClient,
            _ eventNotificationCenter: EventNotificationCenter,
            _ syncRepository: SyncRepository,
            _ extensionLifecycle: NotificationExtensionLifecycle,
            _ backgroundTaskScheduler: BackgroundTaskScheduler?,
            _ internetConnection: InternetConnection,
            _ keepConnectionAliveInBackground: Bool
        ) -> ConnectionRecoveryHandler = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                syncRepository: $2,
                extensionLifecycle: $3,
                backgroundTaskScheduler: $4,
                internetConnection: $5,
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: DefaultTimer.self,
                keepConnectionAliveInBackground: $6
            )
        }

        var authenticationRepositoryBuilder = AuthenticationRepository.init

        var syncRepositoryBuilder: (
            _ config: ChatClientConfig,
            _ activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>,
            _ activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>,
            _ offlineRequestsRepository: OfflineRequestsRepository,
            _ eventNotificationCenter: EventNotificationCenter,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> SyncRepository = {
            SyncRepository(
                config: $0,
                activeChannelControllers: $1,
                activeChannelListControllers: $2,
                offlineRequestsRepository: $3,
                eventNotificationCenter: $4,
                database: $5,
                apiClient: $6
            )
        }

        var callRepositoryBuilder: (
            _ apiClient: APIClient
        ) -> CallRepository = {
            CallRepository(apiClient: $0)
        }

        var channelRepositoryBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelRepository = {
            ChannelRepository(database: $0, apiClient: $1)
        }

        var messageRepositoryBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageRepository = {
            MessageRepository(database: $0, apiClient: $1)
        }

        var offlineRequestsRepositoryBuilder: (
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
