//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ConnectionEvent: Event {
    var connectionId: String { get }
}

public final class HealthCheckEvent: ConnectionEvent, Sendable {
    public let connectionId: String

    init(connectionId: String) {
        self.connectionId = connectionId
    }
    
    public func healthcheck() -> HealthCheckInfo? {
        HealthCheckInfo(connectionId: connectionId)
    }
}

extension HealthCheckEventDTO: EventDTO {
    func toDomainEvent(session: DatabaseSession) -> Event? {
        HealthCheckEvent(connectionId: connectionId)
    }
}

extension ConnectedEventDTO: EventDTO {
    func toDomainEvent(session: DatabaseSession) -> Event? {
        HealthCheckEvent(connectionId: connectionId)
    }
}

extension ConnectionErrorEventDTO: EventDTO {
    func toDomainEvent(session: DatabaseSession) -> Event? {
        nil
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
