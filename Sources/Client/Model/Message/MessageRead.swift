//
//  MessageRead.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 16/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message read state. User + last read date + unread message count.
public struct MessageRead: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadDate = "last_read"
        case unreadMessageCount = "unread_messages"
    }
    
    /// A user (see `User`).
    public let user: User
    /// A last read date by the user.
    public let lastReadDate: Date
    /// Unread message count for the user.
    public let unreadMessageCount: Int
    
    /// Init a message read.
    ///
    /// - Parameters:
    ///   - user: a user.
    ///   - lastReadDate: the last read date.
    ///   - unreadMessages: Unread message count
    public init(user: User, lastReadDate: Date, unreadMessageCount: Int) {
        self.user = user
        self.lastReadDate = lastReadDate
        self.unreadMessageCount = unreadMessageCount
    }
    
    public static func == (lhs: MessageRead, rhs: MessageRead) -> Bool {
        lhs.user == rhs.user
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
