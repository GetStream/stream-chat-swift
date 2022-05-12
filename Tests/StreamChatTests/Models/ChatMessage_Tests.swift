//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatMessage_Tests: XCTestCase {
    func test_isPinned_whenHasPinDetails_shouldReturnTrue() {
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
    
    func test_isPinned_whenEmptyPinDetails_shouldReturnFalse() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            pinDetails: nil
        )
        
        XCTAssertFalse(message.isPinned)
    }

    func test_isPinned_whenEmptyExpireDate_shouldReturnTrue() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            pinDetails: MessagePinDetails(
                pinnedAt: Date.distantPast,
                pinnedBy: ChatUser.mock(id: .anonymous),
                expiresAt: nil
            )
        )

        XCTAssertTrue(message.isPinned)
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
    
    // MARK: - deliveryStatus
    
    func test_deliveryStatus_whenMessageIsAuthoredByAnotherUser_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )
        
        XCTAssertNil(message.deliveryStatus)
    }
    
    func test_deliveryStatus_whenMessageIsError_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .error,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )
        
        XCTAssertNil(message.deliveryStatus)
    }
    
    func test_deliveryStatus_whenMessageIsSystem_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .system,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )
        
        XCTAssertNil(message.deliveryStatus)
    }
    
    func test_deliveryStatus_whenMessageIsEphemeral_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )
        
        XCTAssertNil(message.deliveryStatus)
    }
    
    func test_deliveryStatus_whenRegularMessageHasPendingLocalState_returnsPending() {
        for localState in LocalMessageState.pendingStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .regular,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )
            
            XCTAssertEqual(message.deliveryStatus, .pending)
        }
    }
    
    func test_deliveryStatus_whenThreadReplyHasPendingLocalState_returnsPending() {
        for localState in LocalMessageState.pendingStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .reply,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )
            
            XCTAssertEqual(message.deliveryStatus, .pending)
        }
    }
    
    func test_deliveryStatus_whenRegularMessageHasFailedLocalState_returnsFailed() {
        for localState in LocalMessageState.failedStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .regular,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )
            
            XCTAssertEqual(message.deliveryStatus, .failed)
        }
    }
    
    func test_deliveryStatus_whenThreadReplyHasFailedLocalState_returnsFailed() {
        for localState in LocalMessageState.failedStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .reply,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )
            
            XCTAssertEqual(message.deliveryStatus, .failed)
        }
    }
    
    func test_deliveryStatus_whenRegularMessageIsSent_returnsSent() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )
        
        XCTAssertEqual(message.deliveryStatus, .sent)
    }
    
    func test_deliveryStatus_whenThreadReplyIsSent_returnsSent() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .reply,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )
        
        XCTAssertEqual(message.deliveryStatus, .sent)
    }
    
    func test_deliveryStatus_whenRegularMessageIsRead_returnsRead() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )
        
        XCTAssertEqual(message.deliveryStatus, .read)
    }
    
    func test_deliveryStatus_whenThreadReplyIsRead_returnsRead() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .reply,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )
        
        XCTAssertEqual(message.deliveryStatus, .read)
    }
}
