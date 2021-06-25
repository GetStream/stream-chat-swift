//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ChatMessage_Tests: XCTestCase {
    func test_isPinnedShouldReturnTrue() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            pinDetails: _MessagePinDetails(
                pinnedAt: Date.distantPast,
                pinnedBy: ChatUser.mock(id: .anonymous),
                expiresAt: Date.distantFuture
            )
        )
        
        XCTAssertTrue(message.isPinned)
    }
    
    func test_isPinnedShouldReturnFalse() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            pinDetails: nil
        )
        
        XCTAssertFalse(message.isPinned)
    }
}
