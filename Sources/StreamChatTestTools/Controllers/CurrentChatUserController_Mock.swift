//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class CurrentChatUserController_Mock<ExtraData: ExtraDataTypes>: _CurrentChatUserController<ExtraData> {
    public static func mock() -> CurrentChatUserController_Mock<ExtraData> {
        .init(client: .mock())
    }
    
    public var currentUser_mock: _CurrentChatUser<ExtraData.User>?
    override public var currentUser: _CurrentChatUser<ExtraData.User>? {
        currentUser_mock
    }
}
