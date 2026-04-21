//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class LabelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var harmLabels: [String]?
    var name: String
    var phraseListIds: [Int]?

    init(harmLabels: [String]? = nil, name: String, phraseListIds: [Int]? = nil) {
        self.harmLabels = harmLabels
        self.name = name
        self.phraseListIds = phraseListIds
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case harmLabels = "harm_labels"
        case name
        case phraseListIds = "phrase_list_ids"
    }

    static func == (lhs: LabelResponse, rhs: LabelResponse) -> Bool {
        lhs.harmLabels == rhs.harmLabels &&
            lhs.name == rhs.name &&
            lhs.phraseListIds == rhs.phraseListIds
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(harmLabels)
        hasher.combine(name)
        hasher.combine(phraseListIds)
    }
}
