//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageActionRequest: Sendable, Encodable, JSONEncodable {
    /// ReadOnlyData to execute command with
    let formData: [String: String]

    init(formData: [String: String]) {
        self.formData = formData
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case formData = "form_data"
    }
}
