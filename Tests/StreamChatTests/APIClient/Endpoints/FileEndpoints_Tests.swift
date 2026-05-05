//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FileEndpoints_Tests: XCTestCase {
    func test_deleteFile_buildsCorrectly() {
        let channelId: ChannelId = .unique
        let url = "https://example.com/someimage.pdf"

        let endpoint = Endpoint<Response>.deleteChannelFile(type: channelId.type.rawValue, id: channelId.id, url: url)

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "channels/\(channelId.type.rawValue)/\(channelId.id)/file")
        XCTAssertNil(endpoint.body)
    }

    func test_deleteImage_buildsCorrectly() {
        let channelId: ChannelId = .unique
        let url = "https://example.com/someimage.pdf"

        let endpoint = Endpoint<Response>.deleteChannelImage(type: channelId.type.rawValue, id: channelId.id, url: url)

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "channels/\(channelId.type.rawValue)/\(channelId.id)/image")
        XCTAssertNil(endpoint.body)
    }
}
