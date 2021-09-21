//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ConnectionEvent: Event {
    var connectionId: String { get }
}

public struct HealthCheckEvent: ConnectionEvent, EventDTO {
    public let connectionId: String
    
    let payload: EventPayload
    
    init(from eventResponse: EventPayload) throws {
        guard let connectionId = eventResponse.connectionId else {
            throw ClientError.EventDecoding(missingValue: "connectionId", for: Self.self)
        }
        
        self.connectionId = connectionId
        payload = eventResponse
    }
    
    init(connectionId: String) {
        self.connectionId = connectionId
        payload = EventPayload(
            eventType: .healthCheck,
            connectionId: connectionId,
            cid: nil,
            currentUser: nil,
            channel: nil
        )
    }
}

/// Emitted when `Client` changes it's connection status. You can listen to this event and indicate the different connection
/// states in the UI (banners like "Offline", "Reconnecting"", etc.).
public struct ConnectionStatusUpdated: Event {
    /// The current connection status of `Client`
    public let connectionStatus: ConnectionStatus
    
    // Underlying WebSocketConnectionState
    let webSocketConnectionState: WebSocketConnectionState
    
    init(webSocketConnectionState: WebSocketConnectionState) {
        connectionStatus = .init(webSocketConnectionState: webSocketConnectionState)
        self.webSocketConnectionState = webSocketConnectionState
    }
}
