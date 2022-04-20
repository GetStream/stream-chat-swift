//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DeviceEndpoints_Tests: XCTestCase {
    func test_addDevice_whenPushProviderIsAPN() {
        let userId: UserId = .unique
        let deviceId: String = .unique

        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: .devices,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user_id": userId, "id": deviceId, "push_provider": "apn"]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .addDevice(
            userId: userId,
            deviceId: deviceId,
            pushProvider: .apn
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("devices", endpoint.path.value)
    }

    func test_addDevice_whenPushProviderIsFirebase() {
        let userId: UserId = .unique
        let deviceId: String = .unique

        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: .devices,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user_id": userId, "id": deviceId, "push_provider": "firebase"]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .addDevice(
            userId: userId,
            deviceId: deviceId,
            pushProvider: .firebase
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("devices", endpoint.path.value)
    }
    
    func test_removeDevice_buildsCorrectly() {
        let userId: UserId = .unique
        let deviceId: String = .unique
        
        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: .devices,
            method: .delete,
            queryItems: ["user_id": userId, "id": deviceId],
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .removeDevice(userId: userId, deviceId: deviceId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("devices", endpoint.path.value)
    }
    
    func test_devices_buildsCorrectly() {
        let userId: UserId = .unique
        
        let expectedEndpoint: Endpoint<DeviceListPayload> = .init(
            path: .devices,
            method: .get,
            queryItems: ["user_id": userId],
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<DeviceListPayload> = .devices(userId: userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("devices", endpoint.path.value)
    }
}
