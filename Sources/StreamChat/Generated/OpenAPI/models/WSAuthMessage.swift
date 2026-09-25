//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class WSAuthMessage: Sendable, Codable, JSONEncodable {
    /// Channel-member custom keys to project onto message.member for messages this connection receives (opt-in; capped, off by default).
    let memberCustomInclude: [String]?
    /// List of products to subscribe to. One of: chat, video, feeds
    let products: [String]?
    /// JWT token for authentication
    let token: String
    let userDetails: ConnectUserDetailsRequest

    init(
        memberCustomInclude: [String]? = nil,
        products: [String]? = nil,
        token: String,
        userDetails: ConnectUserDetailsRequest
    ) {
        self.memberCustomInclude = memberCustomInclude
        self.products = products
        self.token = token
        self.userDetails = userDetails
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case memberCustomInclude = "member_custom_include"
        case products
        case token
        case userDetails = "user_details"
    }
}
