//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The endpoints related to live location services.
///
/// - Note: Creating new location is part of MessageEndpoints.swift file, since it is done when creating a message.
extension Endpoint {
    static func updateLiveLocation(request: LiveLocationUpdateRequestPayload) -> Endpoint<SharedLocationPayload> {
        .init(
            path: .liveLocations,
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )
    }

    static func stopLiveLocation(request: StopLiveLocationRequestPayload) -> Endpoint<SharedLocationPayload> {
        .init(
            path: .liveLocations,
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )
    }

    static func currentUserActiveLiveLocations() -> Endpoint<ActiveLiveLocationsResponsePayload> {
        .init(
            path: .liveLocations,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
    }
}
