//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension EventSender {
    func sendEvent<Payload: CustomEventPayload>(_ payload: Payload, to cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            sendEvent(payload, to: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
}
