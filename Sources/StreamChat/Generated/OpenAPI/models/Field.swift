//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Field: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var short: Bool
    var title: String
    var value: String

    init(short: Bool, title: String, value: String) {
        self.short = short
        self.title = title
        self.value = value
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case short
        case title
        case value
    }

    static func == (lhs: Field, rhs: Field) -> Bool {
        lhs.short == rhs.short &&
            lhs.title == rhs.title &&
            lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(short)
        hasher.combine(title)
        hasher.combine(value)
    }
}
