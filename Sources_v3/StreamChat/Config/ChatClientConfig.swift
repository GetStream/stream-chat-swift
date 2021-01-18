//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    /// The API key can be obtained by registering on [our website](https://getstream.io/chat/trial/).
    ///
    public let apiKey: APIKey
    
    /// The folder `ChatClient` uses to store its local cache files.
    public var localStorageFolderURL: URL? = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.first
    }()
    
    /// The datacenter `ChatClient` uses for connecting.
    public var baseURL: BaseURL = .dublin
    
    /// Determines whether `ChatClient` caches the data locally. This makes it possible to browse the existing chat data also
    /// when the internet connection is not available.
    public var isLocalStorageEnabled: Bool = true
    
    /// If set to `true`, `ChatClient` resets the local cache on the start.
    ///
    /// You should set `shouldFlushLocalStorageOnStart = true` every time the changes in your code makes the local cache invalid.
    ///
    /// For example, when you change your custom `ExtraData` types, the cached data can't be decoded, and the cache has to be
    /// flushed.
    ///
    public var shouldFlushLocalStorageOnStart: Bool = false
    
    /// `ChatChannel` specific settings.
//    public var channel = Channel()
    
    /// Flag for setting a ChatClient instance in connection-less mode.
    /// A connection-less client is not able to connect to websocket and will not
    /// receive websocket events. It can still observe and mutate database.
    /// This flag is automatically set to `false` for app extensions
    /// **Warning**: There should be at max 1 active client at the same time, else it can lead to undefined behavior.
    public var isClientInActiveMode: Bool

    /// If set to `true` the `ChatClient` will automatically establish a web-socket
    /// connection to listen to the updates when `reloadUserIfNeeded` is called.
    ///
    /// If set to `false` the connection won't be established automatically
    /// but has to be initiated manually by calling `connect`.
    ///
    /// Is `true` by default.
    public var shouldConnectAutomatically = true
    
    /// Creates a new instance of `ChatClientConfig`.
    ///
    /// - Parameter apiKey: The API key of the chat app the `ChatClient` connects to.
    ///
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

// extension ChatClientConfig {
//    /// `ChatChannel` specific settings.
//    public struct Channel {
//        // example ...
//        public var isReplyInChannelAllowed = true
//
//        /// When `KeystrokeEvent` is sent, the time interval before the `TypingStop` event is automatically sent.
//        public var keystrokeEventTimeout: TimeInterval = 5
//    }
//
//    public struct Message {
//        // something
//    }
// }

/// A struct representing an API key of the chat app.
///
/// An API key can be obtained by registering on [our website](https://getstream.io/chat/trial/).
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
