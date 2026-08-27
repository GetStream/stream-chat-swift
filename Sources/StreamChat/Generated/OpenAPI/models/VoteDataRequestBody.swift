//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VoteDataRequestBody: Sendable, Encodable, JSONEncodable {
    let answerText: String?
    let optionId: String?

    init(answerText: String? = nil, optionId: String? = nil) {
        self.answerText = answerText
        self.optionId = optionId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case answerText = "answer_text"
        case optionId = "option_id"
    }
}
