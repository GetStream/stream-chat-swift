//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class APIClient_Tests: XCTestCase {
    func test_request_recordsGeneratedEndpointAndReturnsQueuedResponse() {
        let apiClient = APIClient_Spy()
        let expectedEndpoint: Endpoint<Response> = .deleteDevice(id: "device-id")
        let expectedResponse = Response(duration: "1ms")
        apiClient.test_mockResponseResult(Result<Response, Error>.success(expectedResponse))

        let completionCalled = expectation(description: "completion called")
        nonisolated(unsafe) var receivedResponse: Response?
        apiClient.request(endpoint: expectedEndpoint) { result in
            receivedResponse = result.value
            completionCalled.fulfill()
        }

        wait(for: [completionCalled], timeout: defaultTimeout)

        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(receivedResponse, expectedResponse)
    }

    func test_recoveryRequest_recordsDataEndpointAndReturnsQueuedResponse() {
        let apiClient = APIClient_Spy()
        let endpoint = Endpoint<Data>(
            path: .sendMessage(type: "messaging", id: "general"),
            method: .post,
            requiresConnectionId: true,
            body: nil
        )
        let expectedData = Data("ok".utf8)
        apiClient.test_mockRecoveryResponseResult(Result<Data, Error>.success(expectedData))

        let completionCalled = expectation(description: "completion called")
        nonisolated(unsafe) var receivedData: Data?
        apiClient.recoveryRequest(endpoint: endpoint) { result in
            receivedData = result.value
            completionCalled.fulfill()
        }

        wait(for: [completionCalled], timeout: defaultTimeout)

        XCTAssertEqual(apiClient.recoveryRequest_endpoint, AnyEndpoint(endpoint))
        XCTAssertEqual(receivedData, expectedData)
    }
}
