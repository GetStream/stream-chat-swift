//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PollVote {
    public let id: String
    public let createdAt: Date
    public let updatedAt: Date
    public let pollId: String
    public let isAnswer: Bool
    public let answerText: String?
    public let option: PollOption?
    public let user: ChatUser?
}
