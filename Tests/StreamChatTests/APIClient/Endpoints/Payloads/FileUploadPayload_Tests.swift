//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FileUploadPayload_Tests: XCTestCase {
    func test_payload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FileUploadPayload")
        let payload = try JSONDecoder.default.decode(UploadChannelResponse.self, from: json)
        XCTAssertEqual(payload.file.flatMap(URL.init(string:)), URL(string: "https://i.imgur.com/EgEPqWZ.jpg"))
    }
}
