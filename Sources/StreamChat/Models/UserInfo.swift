//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A model containing user info that's used to connect to chat's backend
public struct UserInfo {
    public let id: UserId
    public let name: String?
    public let imageURL: URL?
    public let extraData: [String: RawJSON]

    public init(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        extraData: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
    }
}
