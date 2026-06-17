//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AttachmentEndpoints_Tests: XCTestCase {
    func test_getOG_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<GetOGResponse> = .getOG(url: "https://getstream.io")

        XCTAssertEqual(endpoint.path.value, "/api/v2/og")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.queryItemsDictionary["url"] ?? nil, "https://getstream.io")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_uploadChannelImage_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<UploadChannelResponse> = .uploadChannelImage(
            type: "messaging",
            id: "general",
            uploadChannelRequest: UploadChannelRequest(file: "image-data")
        )

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/channels/messaging/general/image")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }
}
