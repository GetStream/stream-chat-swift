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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(formData, forKey: .formData)
    }
}
