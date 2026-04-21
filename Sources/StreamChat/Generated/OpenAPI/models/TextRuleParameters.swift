//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TextRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var blocklistMatch: [String]?
    var containsUrl: Bool?
    var harmLabels: [String]?
    var llmHarmLabels: [String: String]?
    var semanticFilterMinThreshold: Float?
    var semanticFilterNames: [String]?
    var severity: String?
    var threshold: Int?
    var timeWindow: String?

    init(blocklistMatch: [String]? = nil, containsUrl: Bool? = nil, harmLabels: [String]? = nil, llmHarmLabels: [String: String]? = nil, semanticFilterMinThreshold: Float? = nil, semanticFilterNames: [String]? = nil, severity: String? = nil, threshold: Int? = nil, timeWindow: String? = nil) {
        self.blocklistMatch = blocklistMatch
        self.containsUrl = containsUrl
        self.harmLabels = harmLabels
        self.llmHarmLabels = llmHarmLabels
        self.semanticFilterMinThreshold = semanticFilterMinThreshold
        self.semanticFilterNames = semanticFilterNames
        self.severity = severity
        self.threshold = threshold
        self.timeWindow = timeWindow
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklistMatch = "blocklist_match"
        case containsUrl = "contains_url"
        case harmLabels = "harm_labels"
        case llmHarmLabels = "llm_harm_labels"
        case semanticFilterMinThreshold = "semantic_filter_min_threshold"
        case semanticFilterNames = "semantic_filter_names"
        case severity
        case threshold
        case timeWindow = "time_window"
    }

    static func == (lhs: TextRuleParameters, rhs: TextRuleParameters) -> Bool {
        lhs.blocklistMatch == rhs.blocklistMatch &&
            lhs.containsUrl == rhs.containsUrl &&
            lhs.harmLabels == rhs.harmLabels &&
            lhs.llmHarmLabels == rhs.llmHarmLabels &&
            lhs.semanticFilterMinThreshold == rhs.semanticFilterMinThreshold &&
            lhs.semanticFilterNames == rhs.semanticFilterNames &&
            lhs.severity == rhs.severity &&
            lhs.threshold == rhs.threshold &&
            lhs.timeWindow == rhs.timeWindow
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blocklistMatch)
        hasher.combine(containsUrl)
        hasher.combine(harmLabels)
        hasher.combine(llmHarmLabels)
        hasher.combine(semanticFilterMinThreshold)
        hasher.combine(semanticFilterNames)
        hasher.combine(severity)
        hasher.combine(threshold)
        hasher.combine(timeWindow)
    }
}
