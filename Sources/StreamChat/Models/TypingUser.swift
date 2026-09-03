//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A user who is currently typing in a channel, with optional slim member info from the typing event.
public struct TypingUser: Hashable, Identifiable, Sendable {
    /// The typing user.
    public let user: ChatUser

    /// Slim channel-member information attached to the typing event, when available.
    public let memberInfo: ChatMemberInfo?

    /// The unique identifier of the typing user.
    public var id: UserId { user.id }

    /// Creates a typing user.
    ///
    /// - Parameters:
    ///   - user: The typing user.
    ///   - memberInfo: Slim channel-member information from the typing event, if any.
    public init(user: ChatUser, memberInfo: ChatMemberInfo? = nil) {
        self.user = user
        self.memberInfo = memberInfo
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(user.id)
    }

    public static func == (lhs: TypingUser, rhs: TypingUser) -> Bool {
        lhs.user == rhs.user && lhs.memberInfo == rhs.memberInfo
    }
}

extension Sequence where Element == TypingUser {
    var chatUsers: Set<ChatUser> {
        Set(map(\.user))
    }
}

extension Sequence where Element == ChatUser {
    var asTypingUsers: Set<TypingUser> {
        Set(map { TypingUser(user: $0) })
    }
}
