//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateGuestResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// the access token to authenticate the user
    var accessToken: String
    /// Duration of the request in milliseconds
    var duration: String
    var user: UserResponse

    init(accessToken: String, duration: String, user: UserResponse) {
        self.accessToken = accessToken
        self.duration = duration
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case accessToken = "access_token"
        case duration
        case user
    }

    static func == (lhs: CreateGuestResponse, rhs: CreateGuestResponse) -> Bool {
        lhs.accessToken == rhs.accessToken &&
            lhs.duration == rhs.duration &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
        hasher.combine(duration)
        hasher.combine(user)
    }
}
