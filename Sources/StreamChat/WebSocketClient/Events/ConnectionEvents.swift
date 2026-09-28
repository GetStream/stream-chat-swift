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

/// The `connection.ok` hello event sent by the v2 connect endpoint after the auth frame is accepted.
/// The `me` payload creates the current user in the database (`EventDataProcessorMiddleware`).
// CHA-5606
final class ConnectedEvent: Event, Decodable {
    let connectionId: String
    let me: OwnUserResponse?

    init(connectionId: String, me: OwnUserResponse?) {
        self.connectionId = connectionId
        self.me = me
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case connectionId = "connection_id"
        case me
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        guard type == .connectionOk else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected the \(EventType.connectionOk.rawValue) event type"
            )
        }
        connectionId = try container.decode(String.self, forKey: .connectionId)
        me = try container.decodeIfPresent(OwnUserResponse.self, forKey: .me)
    }

    func healthcheck() -> HealthCheckInfo? {
        HealthCheckInfo(connectionId: connectionId)
    }
}

// CHA-5606
final class ConnectionErrorEvent: Event, Decodable {
    let apiError: APIError

    init(apiError: APIError) {
        self.apiError = apiError
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        guard type == .connectionError else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected the \(EventType.connectionError.rawValue) event type"
            )
        }
        apiError = try container.decode(APIError.self, forKey: .error)
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
