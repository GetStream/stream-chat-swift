//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A worker used for sending custom events to the backend.
class EventSender: Worker {
    /// Sends a custom event with the given payload to the channel with `cid`.
    ///
    /// - Parameters:
    ///   - payload: A custom event payload.
    ///   - cid: An identifier of a destination channel.
    ///   - completion: Called when the API call is finished. Called with non-nil `Error` if API call fails.
    func sendEvent<Payload: CustomEventPayload>(
        _ payload: Payload,
        to cid: ChannelId,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .sendEvent(payload, cid: cid)) {
            completion?($0.error)
        }
    }
}
