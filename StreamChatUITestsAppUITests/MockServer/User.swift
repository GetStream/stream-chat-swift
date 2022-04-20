//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    func setUpUser(
        event: [String: Any],
        details: [String: String]
    ) -> [String: Any] {
        var user = event[TopLevelKey.user] as! [String: Any]
        user[UserPayloadsCodingKeys.id.rawValue] = details[UserPayloadsCodingKeys.id.rawValue]
        user[UserPayloadsCodingKeys.name.rawValue] = details[UserPayloadsCodingKeys.name.rawValue]
        user[UserPayloadsCodingKeys.imageURL.rawValue] = details[UserPayloadsCodingKeys.imageURL.rawValue]
        user["image_url"] = details[UserPayloadsCodingKeys.imageURL.rawValue]
        return user
    }
}
