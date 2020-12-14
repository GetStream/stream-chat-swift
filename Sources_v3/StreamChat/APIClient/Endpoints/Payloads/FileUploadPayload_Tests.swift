//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class FileUploadPayload_Tests: XCTestCase {
    func test_payload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromFile: "FileUploadPayload")
        let payload = try JSONDecoder.default.decode(FileUploadPayload.self, from: json)
        XCTAssertEqual(payload.file, URL(string: "https://i.imgur.com/EgEPqWZ.jpg"))
    }
}
