//
// MemberEndpointResponse.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberEndpointResponse<UserExtraData: Codable & Hashable>: Decodable {
  let user: UserEndpointReponse<UserExtraData>
}
