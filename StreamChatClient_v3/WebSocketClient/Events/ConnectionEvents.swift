//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ConnectionEvent: Event {
    var connectionId: String { get }
}

public struct HealthCheckEvent: ConnectionEvent, EventWithPayload {
    public let connectionId: String
    var payload: Any
    
    init<ExtraData: ExtraDataTypes>(from eventResponse: EventPayload<ExtraData>) throws {
        guard let connectionId = eventResponse.connectionId else {
            throw ClientError.EventDecoding(missingValue: "connectionId", for: Self.self)
        }
        
        self.connectionId = connectionId
        payload = eventResponse as Any
    }
    
    init(connectionId: String) {
        self.connectionId = connectionId
        payload = EventPayload<DefaultDataTypes>(eventType: .healthCheck,
                                                 connectionId: connectionId,
                                                 cid: nil,
                                                 currentUser: nil,
                                                 channel: nil)
    }
}
