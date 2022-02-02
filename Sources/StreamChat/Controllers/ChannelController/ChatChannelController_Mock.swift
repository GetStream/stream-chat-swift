//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools

class ChatChannelControllerMock: ChatChannelController, Spy {
    var watchActiveChannelError: Error?
    var recordedFunctions: [String] = []

    init(client: ChatClientMock) {
        super.init(channelQuery: .init(cid: .unique), channelListQuery: nil, client: client)
    }

    override func watchActiveChannel(completion: @escaping (Error?) -> Void) {
        record()
        completion(watchActiveChannelError)
    }
}
