//
// User.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing user in chat.
///
/// ... additional info
///
@dynamicMemberLookup
public struct UserModel<ExtraData: Codable & Hashable> {
  // MARK: - Public

  /// The id of the user
  public let id: String

  /// Custom additional data of the user object. You can modify it by setting your custom `ExtraData` type
  /// of `UserModel<ExtraData>.`
  public var extraData: ExtraData?

  /// Creates a new `User` object.
  ///
  /// - Parameter id: The id of the user.
  ///
  public init(id: String) {
    self.id = id
  }
}

extension UserModel {
  public subscript<T>(dynamicMember keyPath: KeyPath<ExtraData, T>) -> T? {
    extraData?[keyPath: keyPath]
  }

  public subscript<T>(dynamicMember keyPath: WritableKeyPath<ExtraData, T?>) -> T? {
    get { extraData?[keyPath: keyPath] }
    set { extraData?[keyPath: keyPath] = newValue }
  }
}

public protocol AnyUser: Codable, Hashable {}
extension UserModel: AnyUser {}

/// The default user extra data type with `name` and `avatarURL` properties.
public struct NameAndAvatarUserData: Codable, Hashable {
  private enum CodingKeys: String, CodingKey {
    case name
    case avatarURL = "image"
  }

  public var name: String?
  public var avatarURL: URL?

  public init(name: String? = nil, avatarURL: URL? = nil) {
    self.name = name
    self.avatarURL = avatarURL
  }
}

/// Convenience `UserModel` typealias with `NameAndAvatarData`.
public typealias User = UserModel<NameAndAvatarUserData>

public extension User {
  /// Creates a new `User` object.
  ///
  /// - Parameters:
  ///   - id: The id of the user
  ///   - name: The name of the user
  ///   - avatarURL: The URL of the user's avatar
  ///
  init(id: String, name: String?, avatarURL: URL?) {
    self.init(id: id)
    self.extraData = NameAndAvatarUserData(name: name, avatarURL: avatarURL)
  }
}
