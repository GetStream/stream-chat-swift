//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallCustomPropertyParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var `operator`: String?
    var propertyKey: String?

    init(operator: String? = nil, propertyKey: String? = nil) {
        self.operator = `operator`
        self.propertyKey = propertyKey
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case `operator`
        case propertyKey = "property_key"
    }

    static func == (lhs: CallCustomPropertyParameters, rhs: CallCustomPropertyParameters) -> Bool {
        lhs.operator == rhs.operator &&
            lhs.propertyKey == rhs.propertyKey
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(`operator`)
        hasher.combine(propertyKey)
    }
}
