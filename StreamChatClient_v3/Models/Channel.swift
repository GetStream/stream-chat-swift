//
// Channel.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelModel<ExtraData: ExtraDataTypes> {
  // MARK: - Public

  public let id: String
  public var extraData: ExtraData.Channel?

  public let members: Set<UserModel<ExtraData.User>>
}

/// A convenience `ChannelModel` typealias with no additional channel data.
public typealias Channel = ChannelModel<DefaultDataTypes>

/// A type-erased version of `ChannelModel<CustomData>`. Not intended to be used directly.
public protocol AnyChannel {}
extension ChannelModel: AnyChannel {}

public struct NoExtraChannelData: Codable, Hashable {}
