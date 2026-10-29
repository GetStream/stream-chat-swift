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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(answerText, forKey: .answerText)
        try container.encodeIfPresent(optionId, forKey: .optionId)
    }
}
