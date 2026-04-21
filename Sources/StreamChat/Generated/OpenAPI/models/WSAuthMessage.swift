//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class WSAuthMessage: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of products to subscribe to. One of: chat, video, feeds
    var products: [String]?
    /// JWT token for authentication
    var token: String
    var userDetails: ConnectUserDetailsRequest

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

    static func == (lhs: WSAuthMessage, rhs: WSAuthMessage) -> Bool {
        lhs.products == rhs.products &&
            lhs.token == rhs.token &&
            lhs.userDetails == rhs.userDetails
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(products)
        hasher.combine(token)
        hasher.combine(userDetails)
    }
}
