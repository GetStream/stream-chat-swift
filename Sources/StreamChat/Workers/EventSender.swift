//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A worker used for sending custom events to the backend.
class EventSender: Worker, @unchecked Sendable {
    /// Sends a custom event with the given payload to the channel with `cid`.
    ///
    /// - Parameters:
    ///   - payload: A custom event payload.
    ///   - cid: An identifier of a destination channel.
    ///   - completion: Called when the API call is finished. Called with non-nil `Error` if API call fails.
    func sendEvent<Payload: CustomEventPayload>(
        _ payload: Payload,
        to cid: ChannelId,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: Endpoint<EventResponse>.sendEvent(
            type: cid.type.rawValue,
            id: cid.id,
            sendEventRequest: payload.asSendEventRequest()
        )) {
            completion?($0.error)
        }
    }
}

extension EventSender {
    func sendEvent<Payload: CustomEventPayload>(_ payload: Payload, to cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            sendEvent(payload, to: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
}
