//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DeviceEndpoints_Tests: XCTestCase {
    func test_addDevice_whenPushProviderIsAPN() {
        let deviceId: String = .unique
        let providerName: String = "Push Configuration Name"
        let createDeviceRequest = CreateDeviceRequest(id: deviceId, pushProvider: .apn, pushProviderName: providerName)

        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: .createDevice,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createDeviceRequest
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .createDevice(createDeviceRequest: createDeviceRequest)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/devices", endpoint.path.value)
    }

    func test_addDevice_whenPushProviderIsFirebase() {
        let deviceId: String = .unique
        let providerName: String = "Push Configuration Name"
        let createDeviceRequest = CreateDeviceRequest(id: deviceId, pushProvider: .firebase, pushProviderName: providerName)

        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: .createDevice,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: createDeviceRequest
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .createDevice(createDeviceRequest: createDeviceRequest)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/devices", endpoint.path.value)
    }

    func test_removeDevice_buildsCorrectly() {
        let deviceId: String = .unique

        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: .deleteDevice,
            method: .delete,
            queryItems: ["id": deviceId],
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .deleteDevice(id: deviceId)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/devices", endpoint.path.value)
    }

    func test_devices_buildsCorrectly() {
        let expectedEndpoint: Endpoint<ListDevicesResponse> = .init(
            path: .listDevices,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<ListDevicesResponse> = .listDevices()

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/devices", endpoint.path.value)
    }
}
