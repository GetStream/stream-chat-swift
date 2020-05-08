//
//  ChannelPresenter+TypingUsers.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

extension ChannelPresenter {
    /// Creates a text for users typing.
    ///
    /// - Returns: a text of users typing, e.g. "<UserName> is typing...", "User1 and 5 others are typing..."
    public func typingUsersText() -> String? {
        guard !typingUsers.isEmpty else {
            return nil
        }
        
        if typingUsers.count == 1, let typingUser = typingUsers.first {
            return "\(typingUser.user.name) is typing..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers[0].user.name) and \(typingUsers[1].user.name) are typing..."
        } else if let typingUser = typingUsers.first {
            return "\(typingUser.user.name) and \(String(typingUsers.count - 1)) others are typing..."
        }
        
        return nil
    }
}

/// A typing user.
public struct TypingUser: Equatable {
    /// A time interval for a users typing timeout.
    public static let timeout: TimeInterval = 30
    
    /// A typiong user.
    public let user: User
    /// A date when the user started typing.
    public let started = Date()
    
    public static func == (lhs: TypingUser, rhs: TypingUser) -> Bool {
        lhs.user == rhs.user
    }
}
