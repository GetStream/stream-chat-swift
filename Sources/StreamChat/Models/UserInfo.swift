//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A model data from which is used to connect chat client for a specific user
public struct UserInfo<ExtraData: ExtraDataTypes> {
    let name: String?
    let imageURL: URL?
    let extraData: ExtraData.User?
    
    public init(
        name: String?,
        imageURL: URL?,
        extraData: ExtraData.User?
    ) {
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
    }
}
