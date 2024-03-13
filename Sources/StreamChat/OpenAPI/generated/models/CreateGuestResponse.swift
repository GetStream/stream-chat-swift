//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CreateGuestResponse: Codable, Hashable {
    public var accessToken: String
    public var duration: String
    public var user: UserResponse

    public init(accessToken: String, duration: String, user: UserResponse) {
        self.accessToken = accessToken
        self.duration = duration
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessToken = "access_token"
        case duration
        case user
    }
}
