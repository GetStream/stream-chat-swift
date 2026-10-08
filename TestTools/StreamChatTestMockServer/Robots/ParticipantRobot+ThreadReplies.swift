//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ParticipantRobot {
    /// Edits the last thread reply.
    @discardableResult
    func editMessageInThread(_ text: String, alsoSendInChannel: Bool = false) -> ParticipantRobot {
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(
            endpoint: "participant/message?action=edit&thread=true&thread_and_channel=\(alsoSendInChannel)",
            body: body
        )
        return self
    }
}
