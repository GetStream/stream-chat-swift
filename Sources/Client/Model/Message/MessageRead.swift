//
//  MessageRead.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 16/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message read state. User + last read date.
public struct MessageRead: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadDate = "last_read"
    }
    
    /// A user (see `User`).
    public let user: User
    /// A last read date by the user.
    public let lastReadDate: Date
    
    /// Init a message read.
    ///
    /// - Parameters:
    ///   - user: a user.
    ///   - lastReadDate: the last read date.
    public init(user: User, lastReadDate: Date) {
        self.user = user
        self.lastReadDate = lastReadDate
    }
    
    public static func == (lhs: MessageRead, rhs: MessageRead) -> Bool {
        return lhs.user == rhs.user
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
