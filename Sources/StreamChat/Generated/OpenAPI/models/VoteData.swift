//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VoteData: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var answerText: String?
    var optionId: String?

    init(answerText: String? = nil, optionId: String? = nil) {
        self.answerText = answerText
        self.optionId = optionId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case answerText = "answer_text"
        case optionId = "option_id"
    }

    static func == (lhs: VoteData, rhs: VoteData) -> Bool {
        lhs.answerText == rhs.answerText &&
            lhs.optionId == rhs.optionId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(answerText)
        hasher.combine(optionId)
    }
}
