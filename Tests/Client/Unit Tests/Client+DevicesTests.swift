//
//  Client+DevicesTests.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class Client_DevicesTests: ClientTestCase {
    
    // MARK: - getDevice() tests
    func test_getDevice_createsRequest() {
        // Action
        client.devices { _ in }

        // Assert
        AssertNetworkRequest(
            method: .get,
            path: "/devices",
            headers: ["Content-Type": "application/json"],
            queryParameters: ["api_key": "test_api_key"],
            body: nil
        )
    }

    func test_getDevice_handlesSuccess() throws {
        // Setup
        let deviceId = "device_id_\(UUID().uuidString)"
        let timestamp = Date(timeIntervalSince1970: 123456789)

        MockNetworkURLProtocol.mockResponse(endpoint: .devices(testUser), responseBody:
            ["devices": [ ["id": deviceId, "created_at": ISO8601DateFormatter().string(from: timestamp)] ]]
        )

        // Action
        let result = try await { self.client.devices($0) }

        // Assert
        AssertResultSuccess(result, [Device(deviceId, created: timestamp)])
        XCTAssertEqual(self.client.user.devices, [Device(deviceId, created: timestamp)])
    }

    func test_getDevice_handlesError() throws {
        // Setup
        let error = TestError.mockError()
        MockNetworkURLProtocol.mockResponse(endpoint: .devices(testUser), error: error)

        // Action
        let result = try await { self.client.devices($0) }

        // Assert
        AssertResultFailure(result, ClientError.requestFailed(error))
    }

    // MARK: - addDevice() tests

    func test_addDeviceWithDeviceID_createsRequest() {
        let testDeviceId = "device_id_\(UUID())"

        // Action
        client.addDevice(deviceId: testDeviceId)

        // Assert
        AssertNetworkRequest(
            method: .post,
            path: "/devices",
            headers: ["Content-Type": "application/json", "Content-Encoding": "gzip"],
            queryParameters: ["api_key": "test_api_key"],
            body: [
                "user_id": testUser.id,
                "id": testDeviceId,
                "push_provider": "apn",
            ]
        )
    }

    func test_addDeviceWithDeviceToken_createsRequest() {
        // Setup
        let deviceToken = Data([1, 2, 3, 4])

        // Action
        client.addDevice(deviceToken: deviceToken)

        // Assert
        AssertNetworkRequest(
            method: .post,
            path: "/devices",
            headers: ["Content-Type": "application/json", "Content-Encoding": "gzip"],
            queryParameters: ["api_key": "test_api_key"],
            body: [
                "user_id": testUser.id,
                "id": "01020304", // the hexadecimal representation of the data
                "push_provider": "apn",
            ]
        )
    }

    func test_addDeviceWithDeviceID_handlesSuccess() throws {
        // Setup
        let deviceId = "device_id_\(UUID().uuidString)"

        MockNetworkURLProtocol.mockResponse(endpoint: .addDevice(deviceId: deviceId, testUser))

        // Action
        let result = try await { done in
            self.client.addDevice(deviceId: deviceId) { done($0) }
        }

        // Assert
        AssertResultSuccess(result, .empty)
        XCTAssertTrue(self.client.user.devices.contains(where: { $0.id == deviceId }))
        XCTAssertTrue(self.client.user.currentDevice?.id == deviceId)
    }

    func test_addDeviceWithDeviceID_handlesError() throws {
        // Setup
        let deviceId = "device_id_\(UUID().uuidString)"
        let error = TestError.mockError()

        MockNetworkURLProtocol.mockResponse(endpoint: .addDevice(deviceId: deviceId, testUser), error: error)

        // Action
        let result = try await { done in
            self.client.addDevice(deviceId: deviceId) { done($0) }
        }

        AssertResultFailure(result, ClientError.requestFailed(error))
                
        AssertAsync {
            Assert.staysFalse(self.client.user.devices.contains(where: { $0.id == deviceId }));
            Assert.staysFalse(self.client.user.currentDevice?.id == deviceId)
        }
    }

    // MARK: - removeDevice() tests

    func test_removeDevice_createsRequest() {
        // Setup
        let testDeviceId = "device_id_\(UUID())"

        // Action
        client.removeDevice(deviceId: testDeviceId)

        // Assert
        AssertNetworkRequest(
            method: .delete,
            path: "/devices",
            headers: ["Content-Type": "application/json"],
            queryParameters: [
                "api_key": "test_api_key",
                "id": testDeviceId,
            ],
            body: nil
        )
    }

    func test_removeDevice_handlesSuccess() throws {
        // Setup
        let device = Device("device_id_\(UUID().uuidString)")
        var user = client.user
        user.devices = [device]
        user.currentDevice = device
        client.set(user: user, token: "test_token")

        assert(user.devices == [device])
        assert(user.currentDevice == device)

        MockNetworkURLProtocol.mockResponse(endpoint: .removeDevice(deviceId: device.id, testUser))

        // Action
        let result = try await { done in
            self.client.removeDevice(deviceId: device.id) { done($0) }
        }

        // Assert
        AssertResultSuccess(result, .empty)
        XCTAssertTrue(self.client.user.devices.allSatisfy { $0.id != device.id })
        XCTAssertTrue(self.client.user.currentDevice?.id != device.id)
    }

    func test_removeDevice_handlesError() throws {
        // Setup
        let error = TestError.mockError()
        let device = Device("device_id_\(UUID().uuidString)")
        var user = client.user
        user.devices = [device]
        user.currentDevice = device
        client.set(user: user, token: "test_token")

        assert(user.devices == [device])
        assert(user.currentDevice == device)
        
        MockNetworkURLProtocol.mockResponse(endpoint: .removeDevice(deviceId: device.id, testUser), error: error)

        // Action
        let result = try await { done in
            self.client.removeDevice(deviceId: device.id) { done($0) }
        }

        // Assert
        AssertResultFailure(result, ClientError.requestFailed(error))
        
        AssertAsync {
            Assert.staysTrue(self.client.user.devices.contains(where: { $0.id == device.id }))
            Assert.staysTrue(self.client.user.currentDevice?.id == device.id)
        }
    }
}
