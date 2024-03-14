//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct WSAuthMessageRequest: Codable, Hashable {
    public var token: String
    public var userDetails: ConnectUserDetailsRequest
    public var products: [String]? = nil

    public init(token: String, userDetails: ConnectUserDetailsRequest, products: [String]? = nil) {
        self.token = token
        self.userDetails = userDetails
        self.products = products
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case token
        case userDetails = "user_details"
        case products
    }
}
