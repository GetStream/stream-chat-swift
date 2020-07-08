//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ConnectionEvent: Event {
    var connectionId: String { get }
}

public struct HealthCheck: ConnectionEvent, EventWithPayload {
    public static var eventRawType: String { "health.check" }
    public let connectionId: String
    var payload: Any
    
    init?<ExtraData: ExtraDataTypes>(from eventResponse: EventPayload<ExtraData>) throws {
        guard eventResponse.eventType == Self.eventRawType else { return nil }
        guard let connectionId = eventResponse.connectionId else {
            throw ClientError.EventDecoding(missingValue: "connectionId", eventType: "HealthCheck")
        }
        self.connectionId = connectionId
        payload = eventResponse as Any
    }
    
    init(connectionId: String) {
        self.connectionId = connectionId
        payload = EventPayload<DefaultDataTypes>.init(eventType: Self.eventRawType,
                                                      connectionId: connectionId,
                                                      channel: nil,
                                                      currentUser: nil,
                                                      cid: nil)
    }
}
