//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

final class AnyAttachmentUpdater_Tests: XCTestCase {
    let sut = AnyAttachmentUpdater()

    func test_update() throws {
        var attachment = ChatMessageImageAttachment(
            id: .init(cid: .unique, messageId: .unique, index: .unique),
            type: .image,
            payload: .init(title: "old", imageRemoteURL: .localYodaImage, extraData: [:]),
            uploadingState: nil
        ).asAnyAttachment

        let expectation = expectation(description: "should update the attachment payload")

        sut.update(&attachment, forPayload: ImageAttachmentPayload.self) { payload in
            payload.title = "new"
            payload.extraData = [
                "thumbnailUrl": .string("fakeUrl")
            ]

            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        let imageAttachment = attachment.attachment(payloadType: ImageAttachmentPayload.self)

        XCTAssertEqual(imageAttachment?.payload.title, "new")
        XCTAssertEqual(imageAttachment?.payload.extraData?["thumbnailUrl"]?.stringValue, "fakeUrl")
    }
}
