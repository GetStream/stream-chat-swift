//
// UserModel.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol UserExtraData: Codable & Hashable {}

public typealias UserId = String

/// A type representing user in chat.
///
/// ... additional info
///
@dynamicMemberLookup
public class UserModel<ExtraData: UserExtraData> {
    // MARK: - Public
    
    /// The id of the user.
    public let id: UserId
    
    /// An indicator whether the user is online.
    public let isOnline: Bool
    
    /// An indicator whether the user is banned.
    public let isBanned: Bool
    
    /// The role of the user.
    public let userRole: UserRole
    
    /// The date the user was created.
    public let userCreatedDate: Date
    
    /// The date the user info was last time update
    public let userUpdatedDate: Date
    
    /// The date the user was last time active.
    public let lastActiveDate: Date?
    
    /// Teams the user belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this, else it'll be empty. Refer to
    /// [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let teams: [String]
    
    /// Custom additional data of the user object. You can modify it by setting your custom `ExtraData` type
    /// of `UserModel<ExtraData>.`
    public let extraData: ExtraData?
    
    // MARK: - Internal
    
    init(
        id: String,
        isOnline: Bool = false,
        isBanned: Bool = false,
        userRole: UserRole = .user,
        createdDate: Date = .init(),
        updatedDate: Date = .init(),
        lastActiveDate: Date? = nil,
        teams: [String] = [],
        extraData: ExtraData? = nil
    ) {
        self.id = id
        self.isOnline = isOnline
        self.isBanned = isBanned
        self.userRole = userRole
        userCreatedDate = createdDate
        userUpdatedDate = updatedDate
        self.lastActiveDate = lastActiveDate
        self.teams = teams
        self.extraData = extraData
    }
}

extension UserModel: Hashable {
    public static func == (lhs: UserModel<ExtraData>, rhs: UserModel<ExtraData>) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension UserModel {
    public subscript<T>(dynamicMember keyPath: KeyPath<ExtraData, T>) -> T? {
        // TODO: Solve double optional
        extraData?[keyPath: keyPath]
    }
}

public enum UserRole: String, Codable, Hashable {
    /// A regular user.
    case user
    /// An administrator.
    case admin
    /// A guest.
    case guest
    /// An anonymous.
    case anonymous
}

/// Convenience `UserModel` typealias with `NameAndImageExtraData`.
public typealias User = UserModel<NameAndImageExtraData>

public extension User {
    /// Creates a new `User` object.
    ///
    /// - Parameters:
    ///   - id: The id of the user
    ///   - name: The name of the user
    ///   - imageURL: The URL of the user's avatar
    ///
    convenience init(id: String, name: String?, imageURL: URL?) {
        self.init(id: id, extraData: NameAndImageExtraData(name: name, imageURL: imageURL))
    }
}
