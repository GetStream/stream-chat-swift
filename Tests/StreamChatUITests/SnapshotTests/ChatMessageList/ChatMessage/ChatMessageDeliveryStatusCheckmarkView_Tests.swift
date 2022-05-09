//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageDeliveryStatusCheckmarkView_Tests: XCTestCase {
    // MARK: - Pending
    
    func test_appearance_pending() {
        AssertSnapshot(
            checkmark(with: .pending),
            variants: .onlyUserInterfaceStyles
        )
    }
    
    func test_accessibility_pending() {
        let checkmark = checkmark(with: .pending)
        
        checkmark.updateContent()
        
        XCTAssertEqual(checkmark.imageView.accessibilityIdentifier, "imageView_pending")
    }
    
    // MARK: - Sent
    
    func test_appearance_sent() {
        AssertSnapshot(
            checkmark(with: .sent),
            variants: .onlyUserInterfaceStyles
        )
    }
    
    func test_accessibility_sent() {
        let checkmark = checkmark(with: .sent)
        
        checkmark.updateContent()
        
        XCTAssertEqual(checkmark.imageView.accessibilityIdentifier, "imageView_sent")
    }
    
    // MARK: - Read
    
    func test_appearance_read() {
        AssertSnapshot(
            checkmark(with: .read),
            variants: .onlyUserInterfaceStyles
        )
    }
    
    func test_accessibility_read() {
        let checkmark = checkmark(with: .read)
        
        checkmark.updateContent()
        
        XCTAssertEqual(checkmark.imageView.accessibilityIdentifier, "imageView_read")
    }
    
    // MARK: - Failed
    
    func test_appearance_failed() {
        AssertSnapshot(
            checkmark(with: .failed),
            variants: .onlyUserInterfaceStyles
        )
    }
    
    func test_accessibility_failed() {
        let checkmark = checkmark(with: .failed)
        
        checkmark.updateContent()
        
        XCTAssertEqual(checkmark.imageView.accessibilityIdentifier, "imageView_failed")
    }
}

private extension ChatMessageDeliveryStatusCheckmarkView_Tests {
    func checkmark(with status: MessageDeliveryStatus) -> ChatMessageDeliveryStatusCheckmarkView {
        let checkmark = ChatMessageDeliveryStatusCheckmarkView().withoutAutoresizingMaskConstraints
        checkmark.content = .init(deliveryStatus: status)
        return checkmark
    }
}
