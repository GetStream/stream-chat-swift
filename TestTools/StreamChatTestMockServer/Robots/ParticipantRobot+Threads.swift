//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ParticipantRobot {
    /// Sends a thread reply and notifies the thread participants about it,
    /// which is the event the thread list uses to update its latest replies and unread count.
    @discardableResult
    func sendMessageInThreadNotifyingThreadParticipants(_ text: String) -> ParticipantRobot {
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(
            endpoint: "participant/message?thread=true&thread_and_channel=false&thread_notification=true",
            body: body
        )
        return self
    }
}
