//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionResponseModel: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var pollOption: PollOptionResponseData

    init(duration: String, pollOption: PollOptionResponseData) {
        self.duration = duration
        self.pollOption = pollOption
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case pollOption = "poll_option"
    }

    static func == (lhs: PollOptionResponseModel, rhs: PollOptionResponseModel) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.pollOption == rhs.pollOption
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(pollOption)
    }
}
