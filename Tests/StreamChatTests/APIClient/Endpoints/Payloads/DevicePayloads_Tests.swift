//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DevicePayloads_Tests: XCTestCase {
    let devicesJSON = XCTestCase.mockData(fromFile: "Devices")
    
    func test_devicesPayload_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(DeviceListPayload.self, from: devicesJSON)
        
        XCTAssertEqual(payload.devices.count, 1)
        XCTAssertEqual(
            payload.devices.first?.id,
            "2552c2ec3ba609bd6ebe5d437e6926de20fde3adae2d2e7f0a5a72bc90285fa5"
        )
    }
}
