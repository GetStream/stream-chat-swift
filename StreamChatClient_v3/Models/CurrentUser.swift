//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserId {
    /// The prefix used for anonymous user ids
    private static let anonymousIdPrefix = "## ANONYMOUS ##"
    
    /// Creates a new anonymous User id.
    static var anonymous: UserId {
        anonymousIdPrefix + " " + UUID().uuidString
    }
    
    var isAnonymousUser: Bool {
        hasPrefix(Self.anonymousIdPrefix)
    }
}

public class CurrentUserModel<ExtraData: UserExtraData>: UserModel<ExtraData> {
    // MARK: - Public
    
    /// A list of devices.
    public let devices: [Device]
    
    /// A list of devices.
    public let currentDevice: Device?
    
    /// Muted users.
    public let mutedUsers: Set<UserModel<ExtraData>>
    
    /// The counts of unread channels and messages.
    public let unreadCount: UnreadCount
    
    public init(
        id: String,
        isOnline: Bool = false,
        isBanned: Bool = false,
        userRole: UserRole = .user,
        createdDate: Date = .init(),
        updatedDate: Date = .init(),
        lastActiveDate: Date? = nil,
        extraData: ExtraData? = nil,
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<UserModel<ExtraData>> = [],
        unreadCount: UnreadCount = .noUnread
    ) {
        self.devices = devices
        self.currentDevice = currentDevice
        self.mutedUsers = mutedUsers
        self.unreadCount = unreadCount
        
        super.init(id: id,
                   isOnline: isOnline,
                   isBanned: isBanned,
                   userRole: userRole,
                   createdDate: createdDate,
                   updatedDate: updatedDate,
                   lastActiveDate: lastActiveDate,
                   extraData: extraData)
    }
}

/// Unread counts of a user.
public struct UnreadCount: Decodable, Equatable {
    public static let noUnread = UnreadCount(channels: 0, messages: 0)
    
    /// The number of unread channels
    public internal(set) var channels: Int
    
    /// The number of unread messagess accross all channels.
    public internal(set) var messages: Int
}
