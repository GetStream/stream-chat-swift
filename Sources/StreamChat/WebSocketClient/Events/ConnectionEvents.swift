//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ConnectionEvent: Event {
    var connectionId: String { get }
}

public final class HealthCheckEvent: ConnectionEvent, EventDTO, Sendable {
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
    
    public func healthcheck() -> HealthCheckInfo? {
        HealthCheckInfo(connectionId: connectionId)
    }
}

final class ConnectionErrorEvent: Event {
    let apiError: APIError
    
    init(from eventResponse: EventPayload) throws {
        guard let apiError = eventResponse.connectionError else {
            throw ClientError.EventDecoding(missingValue: "error", for: Self.self)
        }

        self.apiError = apiError
    }
    
    func error() -> (any Error)? {
        apiError
    }
}

/// Emitted when `Client` changes it's connection status. You can listen to this event and indicate the different connection
/// states in the UI (banners like "Offline", "Reconnecting"", etc.).
public final class ConnectionStatusUpdated: Event {
    /// The current connection status of `Client`
    public let connectionStatus: ConnectionStatus

    // Underlying WebSocketConnectionState
    let webSocketConnectionState: WebSocketConnectionState

    init(webSocketConnectionState: WebSocketConnectionState) {
        connectionStatus = .init(webSocketConnectionState: webSocketConnectionState)
        self.webSocketConnectionState = webSocketConnectionState
    }
}
