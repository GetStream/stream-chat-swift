//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendEventRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var event: EventRequest

    init(event: EventRequest) {
        self.event = event
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case event
    }

    static func == (lhs: SendEventRequest, rhs: SendEventRequest) -> Bool {
        lhs.event == rhs.event
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(event)
    }
}
