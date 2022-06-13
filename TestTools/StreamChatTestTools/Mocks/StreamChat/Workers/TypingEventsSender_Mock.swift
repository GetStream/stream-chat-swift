//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of ChannelUpdater
final class TypingEventsSender_Mock: TypingEventsSender {
    @Atomic var keystroke_cid: ChannelId?
    @Atomic var keystroke_parentMessageId: MessageId?
    @Atomic var keystroke_completion: ((Error?) -> Void)?

    @Atomic var startTyping_cid: ChannelId?
    @Atomic var startTyping_parentMessageId: MessageId?
    @Atomic var startTyping_completion: ((Error?) -> Void)?

    @Atomic var stopTyping_cid: ChannelId?
    @Atomic var stopTyping_parentMessageId: MessageId?
    @Atomic var stopTyping_completion: ((Error?) -> Void)?

    override func keystroke(in cid: ChannelId, parentMessageId: MessageId?, completion: ((Error?) -> Void)? = nil) {
        keystroke_cid = cid
        keystroke_parentMessageId = parentMessageId
        keystroke_completion = completion
    }
    
    override func startTyping(in cid: ChannelId, parentMessageId: MessageId?, completion: ((Error?) -> Void)? = nil) {
        startTyping_cid = cid
        startTyping_parentMessageId = parentMessageId
        startTyping_completion = completion
    }
    
    override func stopTyping(in cid: ChannelId, parentMessageId: MessageId?, completion: ((Error?) -> Void)? = nil) {
        stopTyping_cid = cid
        stopTyping_parentMessageId = parentMessageId
        stopTyping_completion = completion
    }
    
    func cleanUp() {
        keystroke_cid = nil
        keystroke_parentMessageId = nil
        keystroke_completion = nil
        
        startTyping_cid = nil
        startTyping_parentMessageId = nil
        startTyping_completion = nil
        
        stopTyping_cid = nil
        stopTyping_parentMessageId = nil
        stopTyping_completion = nil
    }
}
