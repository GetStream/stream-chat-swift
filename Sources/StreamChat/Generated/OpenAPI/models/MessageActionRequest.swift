//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageActionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// ReadOnlyData to execute command with
    var formData: [String: String]

    init(formData: [String: String]) {
        self.formData = formData
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case formData = "form_data"
    }

    static func == (lhs: MessageActionRequest, rhs: MessageActionRequest) -> Bool {
        lhs.formData == rhs.formData
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(formData)
    }
}
