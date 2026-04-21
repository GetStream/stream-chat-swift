//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ClosedCaptionRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var harmLabels: [String]?
    var llmHarmLabels: [String: String]?
    var threshold: Int?

    init(harmLabels: [String]? = nil, llmHarmLabels: [String: String]? = nil, threshold: Int? = nil) {
        self.harmLabels = harmLabels
        self.llmHarmLabels = llmHarmLabels
        self.threshold = threshold
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case harmLabels = "harm_labels"
        case llmHarmLabels = "llm_harm_labels"
        case threshold
    }

    static func == (lhs: ClosedCaptionRuleParameters, rhs: ClosedCaptionRuleParameters) -> Bool {
        lhs.harmLabels == rhs.harmLabels &&
            lhs.llmHarmLabels == rhs.llmHarmLabels &&
            lhs.threshold == rhs.threshold
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(harmLabels)
        hasher.combine(llmHarmLabels)
        hasher.combine(threshold)
    }
}
