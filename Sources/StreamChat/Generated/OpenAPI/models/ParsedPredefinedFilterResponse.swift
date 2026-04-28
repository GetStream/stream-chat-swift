//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ParsedPredefinedFilterResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var filter: [String: RawJSON]
    var name: String
    var sort: [SortParamRequestOpenAPI]?

    init(filter: [String: RawJSON], name: String, sort: [SortParamRequestOpenAPI]? = nil) {
        self.filter = filter
        self.name = name
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filter
        case name
        case sort
    }

    static func == (lhs: ParsedPredefinedFilterResponse, rhs: ParsedPredefinedFilterResponse) -> Bool {
        lhs.filter == rhs.filter &&
            lhs.name == rhs.name &&
            lhs.sort == rhs.sort
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filter)
        hasher.combine(name)
        hasher.combine(sort)
    }
}
