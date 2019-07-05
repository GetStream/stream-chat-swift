//
//  MessageRead.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 16/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message read state. User + last read date.
public struct MessageRead: Decodable, Equatable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadDate = "last_read"
    }
    
    /// A user (see `User`).
    let user: User
    /// A last read date by the user.
    let lastReadDate: Date
    
    public static func == (lhs: MessageRead, rhs: MessageRead) -> Bool {
        return lhs.user == rhs.user
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
