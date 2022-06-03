//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatUserSearchController_Mock: ChatUserSearchController {
    public static func mock(client: ChatClient? = nil) -> ChatUserSearchController_Mock {
        .init(client: client ?? .mock())
    }
    
    public var users_mock: [ChatUser]?
    override public var userArray: [ChatUser] {
        users_mock ?? super.userArray
    }
    
    override public func search(query: UserListQuery, completion: ((Error?) -> Void)? = nil) {
        completion?(nil)
    }
    
    override public func search(term: String?, completion: ((Error?) -> Void)? = nil) {
        users_mock = users_mock?.filter { user in
            user.name?.contains(term ?? "") ?? true
        }
        completion?(nil)
    }
}
