//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class DeviceEndpoints_Tests: XCTestCase {
    func test_addDevice_buildsCorrectly() {
        let userId: UserId = .unique
        let deviceId: String = .unique
        
        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: "devices",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user_id": userId, "id": deviceId, "push_provider": "apn"]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .addDevice(userId: userId, deviceId: deviceId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_removeDevice_buildsCorrectly() {
        let userId: UserId = .unique
        let deviceId: String = .unique
        
        let expectedEndpoint: Endpoint<EmptyResponse> = .init(
            path: "devices",
            method: .delete,
            queryItems: ["user_id": userId, "id": deviceId],
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .removeDevice(userId: userId, deviceId: deviceId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_devices_buildsCorrectly() {
        let userId: UserId = .unique
        
        let expectedEndpoint: Endpoint<DeviceListPayload> = .init(
            path: "devices",
            method: .get,
            queryItems: ["user_id": userId],
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<DeviceListPayload> = .devices(userId: userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
