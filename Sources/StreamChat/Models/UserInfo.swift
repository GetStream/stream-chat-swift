//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A model containing user info that's used to connect to chat's backend
public struct UserInfo<ExtraData: ExtraDataTypes> {
    public let id: UserId
    public let name: String?
    public let imageURL: URL?
    public let extraData: ExtraData.User
    
    public init(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        extraData: ExtraData.User = .defaultValue
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
    }
}
