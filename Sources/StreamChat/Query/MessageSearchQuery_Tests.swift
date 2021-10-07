//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageSearchFilterScope_Tests: StressTestCase {
    func test_withAttachments() {
        // Declare attachment types
        let attachmentTypes: Set<AttachmentType> = [.image, .video]
        
        // Build a filter
        let filter: Filter<MessageSearchFilterScope> = .withAttachments(attachmentTypes)
        
        // Assert correct filter is built
        XCTAssertEqual(filter.key, FilterKey<MessageSearchFilterScope, AttachmentType>.hasAttachmentsOfType.rawValue)
        XCTAssertEqual(filter.operator, FilterOperator.in.rawValue)
        XCTAssertEqual(Set(filter.value as! [AttachmentType]), attachmentTypes)
    }
}
