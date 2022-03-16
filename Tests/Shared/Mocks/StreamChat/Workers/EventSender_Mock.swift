//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `EventSender`
final class EventSenderMock: EventSender {
    @Atomic var sendEvent_payload: Any?
    @Atomic var sendEvent_cid: ChannelId?
    @Atomic var sendEvent_completion: ((Error?) -> Void)?
    
    override func sendEvent<Payload: CustomEventPayload>(
        _ payload: Payload,
        to cid: ChannelId,
        completion: ((Error?) -> Void)? = nil
    ) {
        sendEvent_payload = payload
        sendEvent_cid = cid
        sendEvent_completion = completion
    }
    
    func cleanUp() {
        sendEvent_payload = nil
        sendEvent_cid = nil
        sendEvent_completion = nil
    }
}
