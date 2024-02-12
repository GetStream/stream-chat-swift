//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageActionRequest: Codable, Hashable {
    public var formData: [String: String]
    public var iD: String? = nil
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(formData: [String: String], iD: String? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.formData = formData
        self.iD = iD
        self.userId = userId
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case formData = "form_data"
        case iD = "ID"
        case userId = "user_id"
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formData, forKey: .formData)
        try container.encode(iD, forKey: .iD)
        try container.encode(userId, forKey: .userId)
        try container.encode(user, forKey: .user)
    }
}
