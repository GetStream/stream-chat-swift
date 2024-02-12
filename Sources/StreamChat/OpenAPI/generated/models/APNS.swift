//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct APNS: Codable, Hashable {
    public var body: String
    public var title: String

    public init(body: String, title: String) {
        self.body = body
        self.title = title
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case body
        case title
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(body, forKey: .body)
        try container.encode(title, forKey: .title)
    }
}
