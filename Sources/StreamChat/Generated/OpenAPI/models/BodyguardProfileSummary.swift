//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BodyguardProfileSummary: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var displayName: String?
    var name: String
    var textType: String?

    init(displayName: String? = nil, name: String, textType: String? = nil) {
        self.displayName = displayName
        self.name = name
        self.textType = textType
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case displayName = "display_name"
        case name
        case textType = "text_type"
    }

    static func == (lhs: BodyguardProfileSummary, rhs: BodyguardProfileSummary) -> Bool {
        lhs.displayName == rhs.displayName &&
            lhs.name == rhs.name &&
            lhs.textType == rhs.textType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
        hasher.combine(name)
        hasher.combine(textType)
    }
}
