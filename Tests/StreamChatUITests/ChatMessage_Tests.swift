//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class ChatMessage_Tests: XCTestCase {
    func test_lastActiveThreadParticipantNoThreadParticipants() {
        let message = ChatMessage.mock(
            id: .anonymous,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            threadParticipants: []
        )
        
        XCTAssertNil(message.lastActiveThreadParticipant)
    }
    
    func test_lastActiveThreadParticipantReturnsLastActive() {
        let message = ChatMessage.mock(
            id: .anonymous,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            threadParticipants: [
                ChatUser.mock(
                    id: .anonymous, name: "First", lastActiveAt: Date(timeIntervalSince1970: 10)
                ),
                ChatUser.mock(
                    id: .anonymous, name: "Second", lastActiveAt: Date(timeIntervalSince1970: 50)
                ),
                ChatUser.mock(
                    id: .anonymous, name: "Third", lastActiveAt: Date(timeIntervalSince1970: 30)
                )
            ]
        )
        
        XCTAssertEqual(message.lastActiveThreadParticipant?.name, "Second")
    }
    
    func test_lastActiveThreadParticipantLastActiveIsNotPresentFallbacksToUserUpdatedAt() {
        let message = ChatMessage.mock(
            id: .anonymous,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            threadParticipants: [
                ChatUser.mock(
                    id: .anonymous,
                    name: "First",
                    updatedAt: Date(timeIntervalSince1970: 10),
                    lastActiveAt: nil
                ),
                ChatUser.mock(
                    id: .anonymous,
                    name: "Second",
                    updatedAt: Date(timeIntervalSince1970: 50),
                    lastActiveAt: nil
                ),
                ChatUser.mock(
                    id: .anonymous,
                    name: "Third",
                    updatedAt: Date(timeIntervalSince1970: 30),
                    lastActiveAt: nil
                )
            ]
        )
        
        XCTAssertEqual(message.lastActiveThreadParticipant?.name, "Second")
    }
}
