//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CDNStorage_Tests: XCTestCase {
    // MARK: - Async uploadAttachment(_:options:)

    func test_uploadAttachment_async_success() async throws {
        let expectedFile = UploadedFile(fileURL: URL(string: "https://cdn.example.com/file.jpg")!, thumbnailURL: nil)
        let storage = CDNStorage_Spy()
        storage.uploadAttachmentResult = .success(expectedFile)

        let result = try await storage.uploadAttachment(.dummy())
        XCTAssertEqual(result.fileURL, expectedFile.fileURL)
    }

    func test_uploadAttachment_async_failure() async {
        let storage = CDNStorage_Spy()
        storage.uploadAttachmentResult = .failure(TestError())

        do {
            _ = try await storage.uploadAttachment(.dummy())
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Async uploadAttachment(localUrl:options:)

    func test_uploadAttachmentLocalUrl_async_success() async throws {
        let expectedFile = UploadedFile(fileURL: URL(string: "https://cdn.example.com/file.pdf")!)
        let storage = CDNStorage_Spy()
        storage.uploadAttachmentResult = .success(expectedFile)

        let result = try await storage.uploadAttachment(localUrl: URL(string: "file:///tmp/file.pdf")!)
        XCTAssertEqual(result.fileURL, expectedFile.fileURL)
    }

    func test_uploadAttachmentLocalUrl_async_failure() async {
        let storage = CDNStorage_Spy()
        storage.uploadAttachmentResult = .failure(TestError())

        do {
            _ = try await storage.uploadAttachment(localUrl: URL(string: "file:///tmp/file.pdf")!)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Async deleteAttachment(remoteUrl:options:)

    func test_deleteAttachment_async_success() async throws {
        let storage = CDNStorage_Spy()
        let url = URL(string: "https://cdn.example.com/file.jpg")!

        try await storage.deleteAttachment(remoteUrl: url)
        XCTAssertEqual(storage.deleteAttachmentRemoteUrl, url)
    }

    func test_deleteAttachment_async_failure() async {
        let storage = CDNStorage_Spy()
        storage.deleteAttachmentResult = TestError()

        do {
            try await storage.deleteAttachment(remoteUrl: URL(string: "https://cdn.example.com/file.jpg")!)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - AttachmentUploadOptions

    func test_uploadOptions_defaultInit() {
        let options = AttachmentUploadOptions()
        XCTAssertNil(options.progress)
    }

    func test_uploadOptions_withProgressClosure() {
        let progressExpectation = expectation(description: "Progress reported")
        let options = AttachmentUploadOptions(progress: { value in
            XCTAssertEqual(value, 0.75)
            progressExpectation.fulfill()
        })
        options.progress?(0.75)
        waitForExpectations(timeout: 1)
    }

    // MARK: - AttachmentDeleteOptions

    func test_deleteOptions_init() {
        _ = AttachmentDeleteOptions()
    }

    // MARK: - UploadedFile

    func test_uploadedFile_initWithURL() {
        let url = URL(string: "https://cdn.example.com/file.jpg")!
        let file = UploadedFile(fileURL: url)
        XCTAssertEqual(file.fileURL, url)
        XCTAssertNil(file.thumbnailURL)
    }

    func test_uploadedFile_initWithThumbnail() {
        let url = URL(string: "https://cdn.example.com/file.jpg")!
        let thumb = URL(string: "https://cdn.example.com/thumb.jpg")!
        let file = UploadedFile(fileURL: url, thumbnailURL: thumb)
        XCTAssertEqual(file.fileURL, url)
        XCTAssertEqual(file.thumbnailURL, thumb)
    }
}

private struct TestError: Error {}
