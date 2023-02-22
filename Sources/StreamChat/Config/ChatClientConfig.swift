//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A configuration object used to configure a `ChatClient` instance.
///
/// The default configuration can be changed the following way:
///   ```
///     var config = ChatClientConfig()
///     config.isLocalStorageEnabled = false
///     config.channel.keystrokeEventTimeout = 15
///   ```
///
public struct ChatClientConfig {
    /// The `APIKey` unique for your chat app.
    ///
    /// The API key can be obtained by registering on [our website](https://getstream.io/chat/\).
    ///
    public let apiKey: APIKey

    /// The security application group ID to use for the local storage. This is needed if you want to share offline storage between
    /// your chat application and extensions. More information is available [here](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
    /// and [here](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW19)
    public var applicationGroupIdentifier: String? {
        didSet {
            localStorageFolderURL = Self.initLocalStorageFolderURL(groupIdentifier: applicationGroupIdentifier)
        }
    }

    /// The folder `ChatClient` uses to store its local cache files.
    public var localStorageFolderURL: URL? = {
        Self.initLocalStorageFolderURL(groupIdentifier: nil)
    }()

    static func initLocalStorageFolderURL(groupIdentifier: String?) -> URL? {
        #if os(macOS)
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return urls.first.map { $0.appendingPathComponent("io.getstream.StreamChat") }
        #else
        if let groupIdentifier = groupIdentifier {
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
                return url
            }
            log
                .error(
                    "Chat is configured to use the App Group: \(groupIdentifier) but the target seems to be not configured correctly"
                )
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #endif
    }

    /// The datacenter `ChatClient` uses for connecting.
    public var baseURL: BaseURL = .default

    /// Determines whether `ChatClient` caches the data locally. This makes it possible to browse the existing chat data also
    /// when the internet connection is not available.
    public var isLocalStorageEnabled: Bool = true

    /// If set to `true`, `ChatClient` resets the local cache on the start.
    ///
    /// You should set `shouldFlushLocalStorageOnStart = true` every time the changes in your code makes the local cache invalid.
    ///
    ///
    public var shouldFlushLocalStorageOnStart: Bool = false

    /// Advanced settings for the local caching and model serialization.
    public var localCaching = LocalCaching()

    /// Flag for setting a ChatClient instance in connection-less mode.
    /// A connection-less client is not able to connect to websocket and will not
    /// receive websocket events. It can still observe and mutate database.
    /// This flag is automatically set to `false` for app extensions
    /// **Warning**: There should be at max 1 active client at the same time, else it can lead to undefined behavior.
    public var isClientInActiveMode: Bool

    /// If set to `true` the `ChatClient` will automatically establish a web-socket
    /// connection to listen to the updates when `refreshToken` is called.
    ///
    /// If set to `false` the connection won't be established automatically
    /// but has to be initiated manually by calling `connect`.
    ///
    /// Is `true` by default.
    @available(
        *,
        deprecated,
        message: "This flag has no effect anymore. The flow for setting and for connecting the user has been unified to the `connectUser` set of methods."
    )
    public var shouldConnectAutomatically = true

    /// If set to `true`, the `ChatClient` will try to stay connected while app is backgrounded.
    /// If set to `false`, websocket disconnects immediately when app is backgrounded.
    ///
    /// This flag aims to reduce unnecessary reconnections while quick app switches,
    /// like when a user just checks a notification or another app.
    /// `ChatClient` starts a background task to keep the connection alive,
    /// and disconnects when background task expires.
    /// `ChatClient` tries to stay connected while in background up to 5 minutes.
    /// Usually, disconnection occurs around 2-3 minutes.
    ///
    /// - Important: If you're using manual connection flow (`shouldConnectAutomatically` set to `false`), this flag is ineffective.
    /// You should handle connection manually when sending app to background
    /// or opening app from background.
    ///
    /// Default value is `true`
    public var staysConnectedInBackground = true

    /// Creates a new instance of `ChatClientConfig`.
    ///
    /// - Parameter apiKey: The API key of the chat app the `ChatClient` connects to.
    ///

    /// Allows to inject a custom API client for uploading attachments, if not specified, `StreamCDNClient` is used.
    /// If a custom `AttachmentUploader` is provided, the custom `CDNClient` won't be used. You should use 1 of them only.
    public var customCDNClient: CDNClient?

    /// Allows to inject a custom attachment uploader. It can be used to have more
    /// control than `CDNClient` to allow changing the attachment payload.
    /// This overrides the custom `CDNClient`. You should use 1 of them only.
    public var customAttachmentUploader: AttachmentUploader?

    /// A component that can be used to change an attachment which was successfully uploaded.
    public var uploadedAttachmentPostProcessor: UploadedAttachmentPostProcessor?

    /// Returns max possible attachment size in bytes.
    /// By default the value is taken from `CDNClient.maxAttachmentSize` type.
    /// But it can be overridden by setting a value here.
    public var maxAttachmentSize: Int64 {
        // TODO: For v5 the maxAttachmentSize should be responsibility of the UI SDK.
        // Since this is not even used in the StreamChat LLC SDK.
        get {
            if let overrideMaxAttachmentSize = self.overrideMaxAttachmentSize {
                return overrideMaxAttachmentSize
            } else if let customCDNClient = customCDNClient {
                return type(of: customCDNClient).maxAttachmentSize
            } else {
                return StreamCDNClient.maxAttachmentSize
            }
        }
        set {
            overrideMaxAttachmentSize = newValue
        }
    }

    /// Used to override the maxAttachmentSize, by setting the value in the config instead of relying on `CDNClient`.
    private var overrideMaxAttachmentSize: Int64?

    /// Returns max number of attachments that can be attached to a message.
    ///
    /// The current limit is `10`.
    public let maxAttachmentCountPerMessage = 10

    /// Specifies the visibility of deleted messages.
    public enum DeletedMessageVisibility: String, CustomStringConvertible, CustomDebugStringConvertible {
        /// All deleted messages are always hidden.
        case alwaysHidden
        /// Deleted message by current user are visible, other deleted messages are hidden.
        case visibleForCurrentUser
        /// Deleted messages are always visible.
        case alwaysVisible

        public var description: String {
            rawValue
        }

        public var debugDescription: String {
            rawValue
        }
    }

    /// Specifies the visibility of deleted messages.
    /// By default, all deleted messages are visible with their content hidden.
    public var deletedMessagesVisibility: DeletedMessageVisibility = .alwaysVisible

    /// Specifies whether `shadowed` messages should be shown in Message list.
    /// For more information, please check "Shadow Bans" docs.
    public var shouldShowShadowedMessages = false

    /// The timeout interval determines the network request timeout interval for all tasks within sessions based on this configuration.
    /// It controls how long (in seconds) a network task should wait for additional data to arrive before giving up
    public var timeoutIntervalForRequest: TimeInterval = 30

    /// Enable/Disable local filtering for Channel lists. When enabled,
    /// whenever a new channel is created,/updated the SDK will try to
    /// match the channel list filter automatically.
    public var isChannelAutomaticFilteringEnabled: Bool = true

    public init(apiKey: APIKey) {
        self.apiKey = apiKey
        isClientInActiveMode = !Bundle.main.isAppExtension
    }
}

extension ChatClientConfig {
    /// Creates a new instance of `ChatClientConfig`.
    ///
    /// - Warning: ⚠️ The provided `apiKeyString` must be non-empty, otherwise an assertion failure is triggered.
    ///
    /// - Parameter apiKeyString: The string with API key of the chat app the `ChatClient` connects to.
    ///
    public init(apiKeyString: String) {
        self.init(apiKey: APIKey(apiKeyString))
    }
}

extension ChatClientConfig {
    /// Advanced settings for the local caching and model serialization.
    public struct LocalCaching: Equatable {
        /// `ChatChannel` specific local caching and model serialization settings.
        public var chatChannel = ChatChannel()
    }

    /// `ChatChannel` specific local caching and model serialization settings.
    public struct ChatChannel: Equatable {
        /// Limit the max number of watchers included in `ChatChannel.lastActiveWatchers`.
        public var lastActiveWatchersLimit = 100
        /// Limit the max number of members included in `ChatChannel.lastActiveMembers`.
        public var lastActiveMembersLimit = 100
        /// Limit the max number of messages included in `ChatChannel.latestMessages`.
        public var latestMessagesLimit = 5
    }
}

/// A struct representing an API key of the chat app.
///
/// An API key can be obtained by registering on [our website](https://getstream.io/chat/trial/\).
///
public struct APIKey: Equatable {
    /// The string representation of the API key
    public let apiKeyString: String

    /// Creates a new `APIKey` from the provided string. Fails, if the string is empty.
    ///
    /// - Warning: The `apiKeyString` must be a non-empty value, otherwise an assertion failure is raised.
    ///
    public init(_ apiKeyString: String) {
        log.assert(apiKeyString.isEmpty == false, "APIKey can't be initialize with an empty string.")
        self.apiKeyString = apiKeyString
    }
}
