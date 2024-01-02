//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

final class MessageSearchFilterScope_Tests: StressTestCase {
    func test_withAttachments_givenAttachmentTypes() {
        let attachmentTypes: Set<AttachmentType> = [.image, .video]

        let filter: Filter<MessageSearchFilterScope> = .withAttachments(attachmentTypes)

        XCTAssertEqual(filter.key, "attachments.type")
        XCTAssertEqual(filter.operator, "$in")
        XCTAssertEqual(Set(filter.value as! [AttachmentType]), attachmentTypes)
    }

    func test_withAttachments() {
        let filter: Filter<MessageSearchFilterScope> = .withAttachments

        XCTAssertEqual(filter.key, "attachments")
        XCTAssertEqual(filter.operator, "$exists")
        XCTAssertEqual(filter.value as! Bool, true)
    }

    func test_withoutAttachments() {
        let filter: Filter<MessageSearchFilterScope> = .withoutAttachments

        XCTAssertEqual(filter.key, "attachments")
        XCTAssertEqual(filter.operator, "$exists")
        XCTAssertEqual(filter.value as! Bool, false)
    }
}
