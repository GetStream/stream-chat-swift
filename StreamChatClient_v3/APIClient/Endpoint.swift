//
// Endpoint.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct Endpoint {
  let path: String
  let method: Method
  let queryItems: [URLQueryItem]
  let jsonQueryItems: [String: Encodable]? // This applies only for GET requests, can we maybe reuse `body` for that?
  let body: Data?
}

extension Endpoint {
  enum Method: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
  }
}

extension Endpoint {
  static func channels(query: ChannelListQuery) -> Endpoint {
    .init(
      path: "channels",
      method: .get,
      queryItems: [],
      jsonQueryItems: ["payload": query],
      body: nil
    )
  }
}
