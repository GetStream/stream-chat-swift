//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DeviceEndpoints_Tests: XCTestCase {
    func test_listDevices_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<ListDevicesResponse> = .listDevices()

        XCTAssertEqual(endpoint.path, "/api/v2/devices")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_createDevice_buildsGeneratedEndpoint() {
        let request = CreateDeviceRequest(id: "device-id", pushProvider: .apn)
        let endpoint: Endpoint<Response> = .createDevice(createDeviceRequest: request)

        XCTAssertEqual(endpoint.path, "/api/v2/devices")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? CreateDeviceRequest, request)
    }

    func test_deleteDevice_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<Response> = .deleteDevice(id: "device-id")

        XCTAssertEqual(endpoint.path, "/api/v2/devices")
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.queryItems?["id"] ?? nil, "device-id")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }
}
