//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A factory component to help build all `ChatClient` dependencies.
class ChatClientFactory {
    let config: ChatClientConfig
    // In the future we could remove the `Environment` struct,
    // since it is a bit redundant now that we have a factory.
    let environment: ChatClient.Environment

    /// Stream-specific request headers.
    private let streamHeaders: [String: String] = [
        "X-Stream-Client": SystemEnvironment.xStreamClientHeader
    ]

    init(config: ChatClientConfig, environment: ChatClient.Environment) {
        self.config = config
        self.environment = environment
    }

    func makeUrlSessionConfiguration() -> URLSessionConfiguration {
        let configuration = config.urlSessionConfiguration
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = config.timeoutIntervalForRequest
        if let customHeaders = configuration.httpAdditionalHeaders {
            configuration.httpAdditionalHeaders = customHeaders.merging(streamHeaders) { _, stream in stream }
        } else {
            configuration.httpAdditionalHeaders = streamHeaders
        }
        return configuration
    }

    func makeApiClientRequestEncoder() -> RequestEncoder {
        environment.requestEncoderBuilder(config.baseURL.restAPIBaseURL, config.apiKey)
    }

    func makeWebSocketRequestEncoder() -> RequestEncoder {
        environment.requestEncoderBuilder(config.baseURL.webSocketBaseURL, config.apiKey)
    }

    func makeApiClient(
        encoder: RequestEncoder,
        urlSessionConfiguration: URLSessionConfiguration
    ) -> APIClient {
        let decoder = environment.requestDecoderBuilder()
        let attachmentUploader = config.customAttachmentUploader ?? StreamAttachmentUploader(
            cdnClient: config.customCDNClient ?? StreamCDNClient(
                encoder: encoder,
                decoder: decoder,
                sessionConfiguration: urlSessionConfiguration
            )
        )
        let apiClient = environment.apiClientBuilder(
            urlSessionConfiguration,
            encoder,
            decoder,
            attachmentUploader
        )
        return apiClient
    }

    func makeWebSocketClient(
        requestEncoder: RequestEncoder,
        urlSessionConfiguration: URLSessionConfiguration,
        eventNotificationCenter: EventNotificationCenter
    ) -> WebSocketClient? {
        environment.webSocketClientBuilder?(
            urlSessionConfiguration,
            requestEncoder,
            EventDecoder(),
            eventNotificationCenter
        )
    }

    func makeDatabaseContainer() -> DatabaseContainer {
        do {
            if config.isLocalStorageEnabled {
                guard let storeURL = config.localStorageFolderURL else {
                    throw ClientError.MissingLocalStorageURL()
                }

                // Create the folder if needed
                try FileManager.default.createDirectory(
                    at: storeURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                let dbFileURL = storeURL.appendingPathComponent(config.apiKey.apiKeyString)
                return environment.databaseContainerBuilder(
                    .onDisk(databaseFileURL: dbFileURL),
                    config.shouldFlushLocalStorageOnStart,
                    config.isClientInActiveMode, // Only reset Ephemeral values in active mode
                    config.localCaching,
                    config.deletedMessagesVisibility,
                    config.shouldShowShadowedMessages
                )
            }

        } catch is ClientError.MissingLocalStorageURL {
            log.assertionFailure("The URL provided in ChatClientConfig can't be `nil`. Falling back to the in-memory option.")

        } catch {
            log.error("Failed to initialize the local storage with error: \(error). Falling back to the in-memory option.")
        }

        return environment.databaseContainerBuilder(
            .inMemory,
            config.shouldFlushLocalStorageOnStart,
            config.isClientInActiveMode, // Only reset Ephemeral values in active mode
            config.localCaching,
            config.deletedMessagesVisibility,
            config.shouldShowShadowedMessages
        )
    }

    func makeEventNotificationCenter(
        databaseContainer: DatabaseContainer,
        currentUserId: @escaping () -> UserId?
    ) -> EventNotificationCenter {
        let center = environment.notificationCenterBuilder(databaseContainer)
        let middlewares: [EventMiddleware] = [
            EventDataProcessorMiddleware(),
            TypingStartCleanupMiddleware(
                emitEvent: { [weak center] in center?.process($0) }
            ),
            ChannelReadUpdaterMiddleware(
                newProcessedMessageIds: { [weak center] in center?.newMessageIds ?? [] }
            ),
            UserTypingStateUpdaterMiddleware(),
            ChannelTruncatedEventMiddleware(),
            MemberEventMiddleware(),
            UserChannelBanEventsMiddleware(),
            UserWatchingEventMiddleware(),
            UserUpdateMiddleware(),
            ChannelVisibilityEventMiddleware(),
            EventDTOConverterMiddleware()
        ]

        center.add(middlewares: middlewares)

        return center
    }
}
