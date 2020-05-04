//
//  Client+DevicesTests.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest

@testable import StreamChatClient

class Client_DevicesTests: XCTestCase {

    var client: Client!
    var testUser: User!

    override func setUp() {
        super.setUp()
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.protocolClasses?.insert(RequestRecorderURLProtocol.self, at: 0)

        let clientConfig = Client.Config(apiKey: "test_api_key")
        // We can create a new `Client` instance unless we use `Client.shared` in tests.
        client = Client(config: clientConfig, defaultURLSessionConfiguration: sessionConfig)

        testUser = User(id: "test_user_\(UUID())")
        client.set(user: testUser, token: "test_token")
    }

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
}
