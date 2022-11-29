//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A model containing user info that's used to connect to chat's backend
public struct UserInfo {
    public let id: UserId
    public let name: String?
    public let imageURL: URL?
    public let isInvisible: Bool
    public let extraData: [String: RawJSON]

    public init(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        isInvisible: Bool = false,
        extraData: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.isInvisible = isInvisible
        self.extraData = extraData
    }
}
