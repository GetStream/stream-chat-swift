//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias MessageId = String

public struct MessageModel<ExtraData: ExtraDataTypes> {
    public let id: String
    public let text: String
    public let type: MessageType
    public let command: String?
    public let createdDate: Date
    public let updatedDate: Date
    public let deletedDate: Date?
    public let args: String?
    public let parentId: String?
    public let showReplyInChannel: Bool
    public let replyCount: Int32
    public let extraData: ExtraData.Message?
    public let isSilent: Bool
    public let reactionScores: [String: Int]
    
    public let user: UserModel<ExtraData.User>
    public let mentionedUsers: Set<UserModel<ExtraData.User>>
}

public typealias Message = MessageModel<DefaultDataTypes>

public protocol MessageExtraData: Codable & Hashable {}
