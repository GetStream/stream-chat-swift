//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TextContentParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var blocklistMatch: [String]?
    var containsUrl: Bool?
    var harmLabels: [String]?
    var labelOperator: String?
    var llmHarmLabels: [String: String]?
    var severity: String?

    init(blocklistMatch: [String]? = nil, containsUrl: Bool? = nil, harmLabels: [String]? = nil, labelOperator: String? = nil, llmHarmLabels: [String: String]? = nil, severity: String? = nil) {
        self.blocklistMatch = blocklistMatch
        self.containsUrl = containsUrl
        self.harmLabels = harmLabels
        self.labelOperator = labelOperator
        self.llmHarmLabels = llmHarmLabels
        self.severity = severity
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklistMatch = "blocklist_match"
        case containsUrl = "contains_url"
        case harmLabels = "harm_labels"
        case labelOperator = "label_operator"
        case llmHarmLabels = "llm_harm_labels"
        case severity
    }

    static func == (lhs: TextContentParameters, rhs: TextContentParameters) -> Bool {
        lhs.blocklistMatch == rhs.blocklistMatch &&
            lhs.containsUrl == rhs.containsUrl &&
            lhs.harmLabels == rhs.harmLabels &&
            lhs.labelOperator == rhs.labelOperator &&
            lhs.llmHarmLabels == rhs.llmHarmLabels &&
            lhs.severity == rhs.severity
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blocklistMatch)
        hasher.combine(containsUrl)
        hasher.combine(harmLabels)
        hasher.combine(labelOperator)
        hasher.combine(llmHarmLabels)
        hasher.combine(severity)
    }
}
