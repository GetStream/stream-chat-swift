//
// ChannelQuery.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel query.
public struct ChannelQuery<ExtraData: ExtraDataTypes>: Encodable {
  private enum CodingKeys: String, CodingKey {
    case data
    case messages
    case members
    case watchers
  }

  /// A channel.
  public let channel: ChannelModel<ExtraData>
  /// A pagination for messages (see `Pagination`).
  public let messagesPagination: Pagination
  /// A pagination for members (see `Pagination`). You can use `.limit` and `.offset`.
  public let membersPagination: Pagination
  /// A pagination for watchers (see `Pagination`). You can use `.limit` and `.offset`.
  public let watchersPagination: Pagination
  /// A query options.
  public let options: QueryOptions

  /// Init a channel query.
  /// - Parameters:
  ///   - channel: a channel.
  ///   - memebers: members of the channel.
  ///   - messagesPagination: a pagination for messages.
  ///   - membersPagination: a pagination for members. You can use `.limit` and `.offset`.
  ///   - watchersPagination: a pagination for watchers. You can use `.limit` and `.offset`.
  ///   - options: a query options (see `QueryOptions`).
  public init(channel: ChannelModel<ExtraData>,
              messagesPagination: Pagination = [],
              membersPagination: Pagination = [],
              watchersPagination: Pagination = [],
              options: QueryOptions = []) {
    self.channel = channel
    self.messagesPagination = messagesPagination
    self.membersPagination = membersPagination
    self.watchersPagination = watchersPagination
    self.options = options
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try options.encode(to: encoder)

    // The channel data only needs for creating it.
//        if !channel.didLoad, !channel.isEmpty {
//            try container.encode(channel, forKey: .data)
//        }

    if !messagesPagination.isEmpty {
      try container.encode(messagesPagination, forKey: .messages)
    }

    if !membersPagination.isEmpty {
      try container.encode(membersPagination, forKey: .members)
    }

    if !watchersPagination.isEmpty {
      try container.encode(watchersPagination, forKey: .watchers)
    }
  }
}

///// An answer for an invite to a channel.
// public struct ChannelInviteAnswer: Encodable {
//    private enum CodingKeys: String, CodingKey {
//        case accept = "accept_invite"
//        case reject = "reject_invite"
//        case message
//    }
//
//    /// A channel.
//    let channel: Channel
//    /// Accept the invite.
//    let accept: Bool?
//    /// Reject the invite.
//    let reject: Bool?
//    /// Additional message.
//    let message: Message?
// }
//
///// An answer for an invite to a channel.
// public struct ChannelInviteResponse: Decodable {
//    /// A channel.
//    let channel: Channel
//    /// Members.
//    let members: [Member]
//    /// Accept the invite.
//    let message: Message?
// }
//
// public struct ChannelUpdate: Encodable {
//    struct ChannelData: Encodable {
//        let channel: Channel
//
//        init(_ channel: Channel) {
//            self.channel = channel
//        }
//
//        func encode(to encoder: Encoder) throws {
//            var container = encoder.container(keyedBy: Channel.EncodingKeys.self)
//            try container.encode(channel.name, forKey: .name)
//            try container.encodeIfPresent(channel.imageURL, forKey: .imageURL)
//            channel.extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a channel extra data")
//        }
//    }
//
//    let data: ChannelData
// }
