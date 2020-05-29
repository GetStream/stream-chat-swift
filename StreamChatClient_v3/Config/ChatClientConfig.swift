//
// ChatClientConfig.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A configuration object used to configure a `ChatClient` instance.
///
/// The default configuration can be changed the following way:
///   ```
///     var config = ChatClient.Config()
///     config.isLocalStorageEnabled = false
///     config.channel.keystrokeEventTimeout = 15
///   ```
///
public struct ChatClientConfig {
  public let apiKey: String

  /// The folder ChatClient uses to store its database files.
  public var localStorageFolderURL: URL? = {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls.first
  }()

  public var baseURL: BaseURL = .dublin

  public var isLocalStorageEnabled: Bool = true

  public var channel = Channel()

  public init(apiKey: String) {
    self.apiKey = apiKey
  }
}

extension ChatClientConfig {
  public struct Channel {
    // example ...
    public var isReplyInChannelAllowed = true

    /// When `KeystrokeEvent` is sent, the time interval before the `UserTypingStop` event is automatically sent.
    public var keystrokeEventTimeout: TimeInterval = 5
  }

  public struct Message {
    // something
  }
}
