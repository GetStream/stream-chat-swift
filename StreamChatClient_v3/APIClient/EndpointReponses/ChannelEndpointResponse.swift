//
// ChannelEndpointResponse.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelEndpointResponse<ExtraData: ExtraDataTypes>: Decodable {
  struct Channel<ExtraData: ExtraDataTypes>: Decodable {
    let id: String
    var extraData: ExtraData.Channel?

    private enum CodingKeys: String, CodingKey {
      case id = "cid"
      case members
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      extraData = try? ExtraData.Channel(from: decoder)
    }
  }

  public let channel: Channel<ExtraData>
  public let members: [MemberEndpointResponse<ExtraData.User>]

  private enum CodingKeys: String, CodingKey {
    case channel
    case members
  }
}
