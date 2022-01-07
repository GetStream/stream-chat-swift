//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `/sync` endpoint
struct MissingEventsPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case eventPayloads = "events"
    }
    
    let eventPayloads: [EventPayload]
}
