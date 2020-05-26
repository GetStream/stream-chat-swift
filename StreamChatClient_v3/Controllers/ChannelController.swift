//
// ChannelController.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelController` allows observing and mutating the controlled channel.
///
///  ... you can do this and that
///
public class ChannelController {
  // MARK: - Public

  public init(channelId: Channel.Id, client: ChatClient) {}
}

extension ChatClient {
  /// Creates a new `ChannelController` for the channel with the provided id.
  ///
  /// - Parameter channelId: The id of the channel this controller represents.
  /// - Returns: A new instance of `ChannelController`.
  ///
  public func channelController(for channelId: Channel.Id) -> ChannelController {
    .init(channelId: channelId, client: self)
  }
}
