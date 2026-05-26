//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ConnectionEvent: Event {
    var connectionId: String { get }
}

public final class HealthCheckEvent: ConnectionEvent, EventDTO, Sendable {
    public let connectionId: String

    init(connectionId: String) {
        self.connectionId = connectionId
    }

    public func healthcheck() -> HealthCheckInfo? {
        HealthCheckInfo(connectionId: connectionId)
    }
}

final class ConnectionErrorEvent: Event, Decodable {
    let apiError: APIError

    init(apiError: APIError) {
        self.apiError = apiError
    }

    private enum CodingKeys: String, CodingKey {
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
