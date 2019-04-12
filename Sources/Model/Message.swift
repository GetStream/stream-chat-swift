//
//  Message.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Message: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case user
        case created = "created_at"
        case updated = "updated_at"
        case text
        case attachments
        case replyCount = "reply_count"
        case reactionCounts = "reaction_counts"
    }
    
    let id: String
    public let type: MessageType
    public let user: User
    public let created: Date
    public let updated: Date
    public let text: String
    public let attachments: [Attachment]
    public let replyCount: Int
    public let reactionCounts: [String: Int]?
}


public enum MessageType: String, Codable {
    case regular
}
