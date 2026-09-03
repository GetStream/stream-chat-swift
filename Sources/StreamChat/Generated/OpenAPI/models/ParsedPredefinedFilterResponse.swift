//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ParsedPredefinedFilterResponse: Sendable, Decodable {
    let filter: [String: RawJSON]
    let name: String
    let sort: [SortParamRequest]?

    init(filter: [String: RawJSON], name: String, sort: [SortParamRequest]? = nil) {
        self.filter = filter
        self.name = name
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filter
        case name
        case sort
    }
}
