//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsNotificationTrigger: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var comment: FeedsNotificationComment?
    var custom: [String: RawJSON]?
    var text: String
    var type: String

    init(comment: FeedsNotificationComment? = nil, custom: [String: RawJSON]? = nil, text: String, type: String) {
        self.comment = comment
        self.custom = custom
        self.text = text
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case comment
        case custom
        case text
        case type
    }

    static func == (lhs: FeedsNotificationTrigger, rhs: FeedsNotificationTrigger) -> Bool {
        lhs.comment == rhs.comment &&
            lhs.custom == rhs.custom &&
            lhs.text == rhs.text &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(comment)
        hasher.combine(custom)
        hasher.combine(text)
        hasher.combine(type)
    }
}
