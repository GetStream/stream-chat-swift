//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

protocol EventContainsMessage {
    var message: StreamChatMessage? { get }
    var type: String { get }
    var channelId: String { get }
    var cid: String { get }
}

protocol EventContainsUser {
    var user: StreamChatUserObject? { get }
}
