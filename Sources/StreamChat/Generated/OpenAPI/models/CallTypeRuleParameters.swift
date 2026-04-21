//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallTypeRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var callType: String?

    init(callType: String? = nil) {
        self.callType = callType
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case callType = "call_type"
    }

    static func == (lhs: CallTypeRuleParameters, rhs: CallTypeRuleParameters) -> Bool {
        lhs.callType == rhs.callType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(callType)
    }
}
