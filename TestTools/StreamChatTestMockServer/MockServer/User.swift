//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

public let userKey = UserPayloadsCodingKeys.self

public extension StreamMockServer {

    func setUpUser(
        source: [String: Any]?,
        details: [String: String] = [:]
    ) -> [String: Any]? {
        guard let user = source?[JSONKey.user] as? [String: Any] else { return nil }
        
        return user.merging(details) { $1 }
    }

    func memberJSONs(for ids: [String]) -> [[String: Any]] {
        ids.map {
            let user = UserDetails.userTuple(withUserId: $0)
            var member = TestData.toJson(.httpMember)
            member[JSONKey.userId] = user.id
            member[userKey.id.rawValue] = user.name
            member[userKey.name.rawValue] = user.name

            if var userJSON = member[JSONKey.user] as? [String: Any] {
                userJSON[userKey.id.rawValue] = user.id
                userJSON[userKey.name.rawValue] = user.name
                userJSON[userKey.imageURL.rawValue] = user.url
                member[JSONKey.user] = userJSON
            }
            return member
        }
    }
}
