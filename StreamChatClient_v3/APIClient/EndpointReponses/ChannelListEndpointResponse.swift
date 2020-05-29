//
// ChannelListEndpointResponse.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelListEndpointResponse<ExtraData: ExtraDataTypes>: Decodable {
  /// A list of channels response (see `ChannelQuery`).
  let channels: [ChannelEndpointResponse<ExtraData>]
}
