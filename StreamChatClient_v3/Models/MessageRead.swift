//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

/// A message read state. User + last read date + unread message count.
public struct MessageRead<ExtraData: UserExtraData>: Hashable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadDate = "last_read"
        case unreadMessagesCount = "unread_messages"
    }
    
    /// A user (see `User`).
    public let user: UserModel<ExtraData>
    /// A last read date by the user.
    public let lastReadDate: Date
    /// Unread message count for the user.
    public let unreadMessagesCount: Int
    
    /// Init a message read.
    ///
    /// - Parameters:
    ///   - user: a user.
    ///   - lastReadDate: the last read date.
    ///   - unreadMessages: Unread message count
    public init(user: UserModel<ExtraData>, lastReadDate: Date, unreadMessagesCount: Int) {
        self.user = user
        self.lastReadDate = lastReadDate
        self.unreadMessagesCount = unreadMessagesCount
    }
    
    public static func == (lhs: MessageRead, rhs: MessageRead) -> Bool {
        lhs.user == rhs.user
    }
}
