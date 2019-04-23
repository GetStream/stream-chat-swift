//
//  Reaction.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Reaction: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case user
        case messageId = "message_id"
        case created = "created_at"
    }
    
    public let type: String
    public let user: User
    public let created: Date
    public let messageId: String
}
