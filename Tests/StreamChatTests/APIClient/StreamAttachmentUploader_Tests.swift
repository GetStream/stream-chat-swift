//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamAttachmentUploader_Tests: XCTestCase {
    func test_upload_whenSuccessful() {
        let expUploadComplete = expectation(description: "should complete upload attachment")
        let expProgressCalled = expectation(description: "should call progress closure")
        let expectedUrl = URL.localYodaImage
        let expectedProgress: Double = 20

        let mockedAttachment = ChatMessageFileAttachment.mock(
            id: .init(cid: .unique, messageId: .unique, index: .unique)
        )
        let mockProgress: ((Double) -> Void) = {
            XCTAssertEqual($0, expectedProgress)
            expProgressCalled.fulfill()
        }

        let cdnClient = CDNClient_Spy()
        cdnClient.uploadAttachmentResult = .success(expectedUrl)
        cdnClient.uploadAttachmentProgress = expectedProgress

        let sut = StreamAttachmentUploader(cdnClient: cdnClient)
        sut.upload(
            mockedAttachment.asAnyAttachment,
            progress: mockProgress
        ) { result in
            let uploadedAttachment = try? result.get()
            XCTAssertEqual(uploadedAttachment?.attachment.id, mockedAttachment.id)
            XCTAssertEqual(uploadedAttachment?.remoteURL, expectedUrl)
            expUploadComplete.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_upload_whenError() {
        let exp = expectation(description: "should complete upload attachment")

        let mockedAttachment = ChatMessageFileAttachment.mock(
            id: .init(cid: .unique, messageId: .unique, index: .unique)
        )

        let expectedError = ClientError("Some Error")
        let cdnClient = CDNClient_Spy()
        cdnClient.uploadAttachmentResult = .failure(expectedError)

        let sut = StreamAttachmentUploader(cdnClient: cdnClient)
        sut.upload(
            mockedAttachment.asAnyAttachment,
            progress: nil
        ) { result in
            XCTAssertEqual(result.error, expectedError)
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
    }
}
