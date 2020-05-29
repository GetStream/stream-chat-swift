//
// UserEndpointReponse.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserEndpointReponse<ExtraData: Codable & Hashable>: Decodable, Hashable {
  private enum CodingKeys: String, CodingKey {
    case id
    case role
    case name
    case avatarURL = "image"
    case isOnline = "online"
    case isBanned = "banned"
    case created = "created_at"
    case updated = "updated_at"
    case lastActiveDate = "last_active"
    case isInvisible = "invisible"
    case devices
    case mutedUsers = "mutes"
    case unreadMessagesCount = "unread_count"
    case unreadChannelsCount = "unread_channels"
    case isAnonymous = "anon"
  }

  public enum Role: String, Codable {
    /// A regular user.
    case user
    /// An administrator.
    case admin
    /// A guest.
    case guest
    /// An anonymous.
    case anonymous
  }

  /// A user id.
  public let id: String
  /// A created date.
  public let created: Date
  /// An updated date.
  public let updated: Date
  /// A last active date.
  public let lastActiveDate: Date?
  /// An indicator if a user is online.
  public let isOnline: Bool
  /// An indicator if a user is invisible.
  public let isInvisible: Bool
  /// An indicator if a user was banned.
  public internal(set) var isBanned: Bool
  /// A user role.
  public let role: Role
  /// An extra data for the user.
  public private(set) var extraData: ExtraData?

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    role = try container.decode(Role.self, forKey: .role)
    created = try container.decode(Date.self, forKey: .created)
    updated = try container.decode(Date.self, forKey: .updated)
    lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
    isOnline = try container.decode(Bool.self, forKey: .isOnline)
    isInvisible = try container.decodeIfPresent(Bool.self, forKey: .isInvisible) ?? false
    self.isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
    self.extraData = try? ExtraData(from: decoder)
  }
}

extension UserModel {
  init(endpointResponse: UserEndpointReponse<ExtraData>) {
    id = endpointResponse.id
    extraData = endpointResponse.extraData
  }
}
