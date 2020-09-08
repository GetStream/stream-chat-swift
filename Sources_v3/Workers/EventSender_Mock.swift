//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

/// Mock implementation of ChannelUpdater
class EventSenderMock<ExtraData: ExtraDataTypes>: EventSender<ExtraData> {
    @Atomic var keystroke_cid: ChannelId?
    @Atomic var keystroke_completion: ((Error?) -> Void)?

    @Atomic var startTyping_cid: ChannelId?
    @Atomic var startTyping_completion: ((Error?) -> Void)?

    @Atomic var stopTyping_cid: ChannelId?
    @Atomic var stopTyping_completion: ((Error?) -> Void)?

    override func keystroke(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        keystroke_cid = cid
        keystroke_completion = completion
    }
    
    override func startTyping(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        startTyping_cid = cid
        startTyping_completion = completion
    }
    
    override func stopTyping(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        stopTyping_cid = cid
        stopTyping_completion = completion
    }
}
