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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.filter = try container.decode([String: RawJSON].self, forKey: .filter)
        self.name = try container.decode(String.self, forKey: .name)
        self.sort = try container.decodeIfPresent([SortParamRequest].self, forKey: .sort)
    }
}
