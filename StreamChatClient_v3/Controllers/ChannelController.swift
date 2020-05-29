//
// ChannelController.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelController` allows observing and mutating the controlled channel.
///
///  ... you can do this and that
///
public class ChannelController<ExtraData: ExtraDataTypes>: Controller {
  // MARK: - Public
}

extension Client {
  /// Creates a new `ChannelController` for the channel with the provided id.
  ///
  /// - Parameter channelId: The id of the channel this controller represents.
  /// - Returns: A new instance of `ChannelController`.
  ///
  public func channelController(for channelId: String) -> ChannelController<ExtraData> {
    .init()
  }
}
