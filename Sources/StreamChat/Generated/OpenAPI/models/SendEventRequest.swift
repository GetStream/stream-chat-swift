//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendEventRequest: Sendable, Encodable, JSONEncodable {
    let event: EventRequest

    init(event: EventRequest) {
        self.event = event
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case event
    }
}
