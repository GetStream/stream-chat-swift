//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class WSAuthMessage: Sendable, Codable, JSONEncodable {
    /// List of products to subscribe to. One of: chat, video, feeds
    let products: [String]?
    /// JWT token for authentication
    let token: String
    let userDetails: ConnectUserDetailsRequest

    init(products: [String]? = nil, token: String, userDetails: ConnectUserDetailsRequest) {
        self.products = products
        self.token = token
        self.userDetails = userDetails
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case products
        case token
        case userDetails = "user_details"
    }
}
