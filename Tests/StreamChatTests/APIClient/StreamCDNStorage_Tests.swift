//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamCDNStorage_Tests: XCTestCase {
    func test_channelImageUploadEndpoint_matchesGeneratedEndpointShape() {
        let cid = ChannelId(type: .messaging, id: "general")
        let endpoint: Endpoint<UploadChannelResponse> = .uploadChannelImage(
            type: cid.type.rawValue,
            id: cid.id,
            uploadChannelRequest: .init()
        )

        XCTAssertEqual(endpoint.path, "/api/v2/chat/channels/messaging/general/image")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_fileUploadEndpoint_matchesGeneratedEndpointShape() {
        let endpoint: Endpoint<FileUploadResponse> = .uploadFile(fileUploadRequest: .init())

        XCTAssertEqual(endpoint.path, "/api/v2/uploads/file")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_deleteAttachmentEndpoints_useGeneratedQueryItems() {
        let fileURL = "https://cdn.example.com/file.txt"
        let imageURL = "https://cdn.example.com/image.png"

        let fileEndpoint: Endpoint<Response> = .deleteFile(url: fileURL)
        let imageEndpoint: Endpoint<Response> = .deleteImage(url: imageURL)

        XCTAssertEqual(fileEndpoint.path, "/api/v2/uploads/file")
        XCTAssertEqual(fileEndpoint.method, .delete)
        XCTAssertEqual(fileEndpoint.queryItems?["url"] ?? nil, fileURL)

        XCTAssertEqual(imageEndpoint.path, "/api/v2/uploads/image")
        XCTAssertEqual(imageEndpoint.method, .delete)
        XCTAssertEqual(imageEndpoint.queryItems?["url"] ?? nil, imageURL)
    }
}
