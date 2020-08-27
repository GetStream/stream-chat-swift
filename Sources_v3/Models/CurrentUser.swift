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

/// A convenience typealias for `CurrentUserModel` with the default data type.
public typealias CurrentUser = CurrentUserModel<DefaultDataTypes.User>

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
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        lastActiveAt: Date? = nil,
        extraData: ExtraData = .defaultValue,
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<UserModel<ExtraData>> = [],
        unreadCount: UnreadCount = .noUnread
    ) {
        self.devices = devices
        self.currentDevice = currentDevice
        self.mutedUsers = mutedUsers
        self.unreadCount = unreadCount
        
        super.init(
            id: id,
            isOnline: isOnline,
            isBanned: isBanned,
            userRole: userRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            extraData: extraData
        )
    }
}
