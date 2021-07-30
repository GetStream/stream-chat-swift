//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `/sync` endpoint
struct MissingEventsPayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case eventPayloads = "events"
    }
    
    let eventPayloads: [EventPayload]
}
