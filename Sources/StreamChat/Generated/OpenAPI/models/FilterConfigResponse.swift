//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FilterConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var aiTextLabels: [String]?
    var configKeys: [String]?
    var llmLabels: [String]

    init(aiTextLabels: [String]? = nil, configKeys: [String]? = nil, llmLabels: [String]) {
        self.aiTextLabels = aiTextLabels
        self.configKeys = configKeys
        self.llmLabels = llmLabels
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case aiTextLabels = "ai_text_labels"
        case configKeys = "config_keys"
        case llmLabels = "llm_labels"
    }

    static func == (lhs: FilterConfigResponse, rhs: FilterConfigResponse) -> Bool {
        lhs.aiTextLabels == rhs.aiTextLabels &&
            lhs.configKeys == rhs.configKeys &&
            lhs.llmLabels == rhs.llmLabels
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(aiTextLabels)
        hasher.combine(configKeys)
        hasher.combine(llmLabels)
    }
}
