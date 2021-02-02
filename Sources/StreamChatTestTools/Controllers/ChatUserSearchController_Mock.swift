//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatUserSearchController_Mock<ExtraData: ExtraDataTypes>: _ChatUserSearchController<ExtraData> {
    public static func mock() -> ChatUserSearchController_Mock<ExtraData> {
        .init(client: .mock())
    }
}
