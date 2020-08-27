//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A configuration object used to configure a `Client` instance.
///
/// The default configuration can be changed the following way:
///   ```
///     var config = ChatClientConfig()
///     config.isLocalStorageEnabled = false
///     config.channel.keystrokeEventTimeout = 15
///   ```
///
public struct ChatClientConfig {
    public let apiKey: APIKey
    
    /// The folder `Client` uses to store its local cache files.
    public var localStorageFolderURL: URL? = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.first
    }()
    
    public var baseURL: BaseURL = .dublin
    
    public var isLocalStorageEnabled: Bool = true
    
    public var channel = Channel()
    
    /// You can optionally provide your custom `TokenProvider` here and it will be called every time a new current user is set.
    /// If you're using self-expiring tokens, setting the provider is mandatory to ensure the tokens can get automatically
    /// refreshed.
    public var tokenProvider: TokenProvider?
    
    public init(apiKey: APIKey) {
        self.apiKey = apiKey
    }
}

extension ChatClientConfig {
    public struct Channel {
        // example ...
        public var isReplyInChannelAllowed = true
        
        /// When `KeystrokeEvent` is sent, the time interval before the `TypingStop` event is automatically sent.
        public var keystrokeEventTimeout: TimeInterval = 5
    }
    
    public struct Message {
        // something
    }
}

/// The API key of the app. You can obtain this value ... TODO
public struct APIKey: Equatable {
    /// The string representation of the API key
    public let apiKeyString: String
    
    /// Creates a new `APIKey` from the provided string. Fails, if the string is empty.
    ///
    /// - Warning: The `apiKeyString` must be a non-empty value, otherwise an assertion failure is raised.
    public init(_ apiKeyString: String) {
        log.assert(apiKeyString.isEmpty == false, "APIKey can't be initialize with an empty string.")
        self.apiKeyString = apiKeyString
    }
}
