//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FileUploadPayload_Tests: XCTestCase {
    func test_payload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FileUploadPayload")
        let payload = try JSONDecoder.default.decode(FileUploadPayload.self, from: json)
        XCTAssertEqual(payload.fileURL, URL(string: "https://i.imgur.com/EgEPqWZ.jpg"))
    }
}
