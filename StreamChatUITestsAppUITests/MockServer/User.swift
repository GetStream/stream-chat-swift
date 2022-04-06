//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    func setUpUser(
        _ user: [String: Any],
        userDetails: [String: String]
    ) -> [String: Any] {
        var updatedUser = user
        updatedUser[UserPayloadsCodingKeys.id.rawValue] =
            userDetails[UserPayloadsCodingKeys.id.rawValue]
        updatedUser[UserPayloadsCodingKeys.name.rawValue] =
            userDetails[UserPayloadsCodingKeys.name.rawValue]
        updatedUser[UserPayloadsCodingKeys.imageURL.rawValue] =
            userDetails[UserPayloadsCodingKeys.imageURL.rawValue]
        updatedUser["image_url"] =
            userDetails[UserPayloadsCodingKeys.imageURL.rawValue]
        return updatedUser
    }
}
