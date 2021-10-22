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
            pinDetails: MessagePinDetails(
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
    
    func test_attachmentWithId_whenAttachmentDoesNotExist_returnsNil() {
        // Create message with attachments
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .anonymous),
            attachments: [
                ChatMessageImageAttachment
                    .mock(id: .unique)
                    .asAnyAttachment,
                ChatMessageFileAttachment
                    .mock(id: .unique)
                    .asAnyAttachment
            ]
        )
        
        // Generate random attachment id
        let randomAttachmentId: AttachmentId = .unique
        
        // Get attachment by non-existing id
        let attachment = message.attachment(with: randomAttachmentId)
        
        // Assert `nil` is returned
        XCTAssertNil(attachment)
    }
    
    func test_attachmentWithId_whenAttachmentExists_returnsIt() {
        // Create attachment
        let targetAttachment: ChatMessageImageAttachment = .mock(id: .unique)
        
        // Create message with target attachment
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .anonymous),
            attachments: [
                targetAttachment.asAnyAttachment,
                ChatMessageFileAttachment
                    .mock(id: .unique)
                    .asAnyAttachment
            ]
        )
        
        // Get attachment by id
        let attachment = message.attachment(with: targetAttachment.id)
        
        // Assert correct attachment is returned.
        XCTAssertEqual(
            attachment?.attachment(payloadType: ImageAttachmentPayload.self),
            targetAttachment
        )
    }

    func test_totalReactionsCount() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            reactionCounts: ["like": 2, "super-like": 3]
        )

        XCTAssertEqual(message.totalReactionsCount, 5)
    }
}
