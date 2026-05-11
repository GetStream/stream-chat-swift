//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FileEndpoints_Tests: XCTestCase {
    func test_uploadFile_buildsGeneratedEndpoint() {
        let request = FileUploadRequest(file: "file-data")
        let endpoint: Endpoint<FileUploadResponse> = .uploadFile(fileUploadRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/uploads/file")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? FileUploadRequest, request)
    }

    func test_deleteImage_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<Response> = .deleteImage(url: "https://example.com/image.png")

        XCTAssertEqual(endpoint.path.value, "/api/v2/uploads/image")
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.queryItems?["url"] ?? nil, "https://example.com/image.png")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }
}
