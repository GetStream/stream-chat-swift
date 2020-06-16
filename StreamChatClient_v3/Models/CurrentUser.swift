//
// CurrentUser.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// TODO: Finish implementation

public class CurrentUser<ExtraData: UserExtraData>: UserModel<ExtraData> {
    // MARK: - Public
    
    /// A list of devices.
    public let devices: [Device]
    
    /// A list of devices.
    public let currentDevice: Device?
    
    /// Muted users.
    public let mutedUsers: Set<UserModel<ExtraData>>
    
    /// The counts of unread channels and messages.
    public let unreadCounts: UnreadCounts
    
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
        unreadCounts: UnreadCounts = .noUnread
    ) {
        self.devices = devices
        self.currentDevice = currentDevice
        self.mutedUsers = mutedUsers
        self.unreadCounts = unreadCounts
        
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
public struct UnreadCounts: Decodable, Equatable {
    public static let noUnread = UnreadCounts(unreadChannels: 0, unreadMessages: 0)
    
    /// The number of unread channels
    public internal(set) var unreadChannels: Int
    
    /// The number of unread messagess accross all channels.
    public internal(set) var unreadMessages: Int
}
