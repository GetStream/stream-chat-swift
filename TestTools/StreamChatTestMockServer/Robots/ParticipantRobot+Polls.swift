//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ParticipantRobot {
    /// Casts a vote in the poll of the newest poll message.
    @discardableResult
    func castPollVote(option: String) -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/poll_vote?option=\(option.urlQueryEncoded)")
        return self
    }

    /// Adds an answer (comment) to the poll of the newest poll message.
    @discardableResult
    func addPollAnswer(_ answer: String) -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/poll_vote?answer=\(answer.urlQueryEncoded)")
        return self
    }

    /// Suggests a new option in the poll of the newest poll message.
    @discardableResult
    func addPollOption(_ option: String) -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/poll_option?text=\(option.urlQueryEncoded)")
        return self
    }
}

private extension String {
    var urlQueryEncoded: String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
