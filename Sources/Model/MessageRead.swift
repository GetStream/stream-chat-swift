//
//  MessageRead.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 16/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageRead: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadDate = "last_read"
    }
    
    let user: User
    let lastReadDate: Date
}

extension MessageRead: Equatable, Hashable {
    
    public static func == (lhs: MessageRead, rhs: MessageRead) -> Bool {
        return lhs.user == rhs.user
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
