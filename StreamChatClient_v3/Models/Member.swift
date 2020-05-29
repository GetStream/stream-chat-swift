//
// Member.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// WIP

public typealias Member = MemberModel<NameAndAvatarUserData>

public struct MemberModel<ExtraData: Codable & Hashable> {
  public let user: UserModel<ExtraData>
}
