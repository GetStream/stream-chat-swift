//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

public extension StreamMockServer {

    func setUpUser(
        source: [String: Any]?,
        details: [String: String]
    ) -> [String: Any]? {
        var user = source?[JSONKey.user] as? [String: Any]
        user?[UserPayloadsCodingKeys.id.rawValue] = details[UserPayloadsCodingKeys.id.rawValue]
        user?[UserPayloadsCodingKeys.name.rawValue] = details[UserPayloadsCodingKeys.name.rawValue]
        user?[UserPayloadsCodingKeys.imageURL.rawValue] = details[UserPayloadsCodingKeys.imageURL.rawValue]
        user?["image_url"] = details[UserPayloadsCodingKeys.imageURL.rawValue]
        return user
    }

    func memberJSONs(for ids: [String]) -> [[String: Any]] {
        ids.map {
            let user = UserDetails.userTuple(withUserId: $0)
            var member = TestData.toJson(.httpMember)
            member[JSONKey.userId] = user.id
            member[UserPayloadsCodingKeys.id.rawValue] = user.name
            member[UserPayloadsCodingKeys.name.rawValue] = user.name

            if var userJSON = member[JSONKey.user] as? [String: Any] {
                userJSON[UserPayloadsCodingKeys.id.rawValue] = user.id
                userJSON[UserPayloadsCodingKeys.name.rawValue] = user.name
                userJSON[UserPayloadsCodingKeys.imageURL.rawValue] = user.url
                member[JSONKey.user] = userJSON
            }
            return member
        }
    }
}
