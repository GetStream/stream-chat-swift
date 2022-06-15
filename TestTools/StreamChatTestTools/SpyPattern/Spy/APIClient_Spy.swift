//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

/// Mock implementation of APIClient allowing easy control and simulation of responses.
final class APIClient_Spy: APIClient, Spy {
    var recordedFunctions: [String] = []

    /// The last endpoint `execute_request` function was called with.
    @Atomic var executeRequest_endpoint: AnyEndpoint?
    @Atomic var executeRequest_completion: Any?
    @Atomic var executeRequest_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []
    
    /// The last endpoint `request` function was called with.
    @Atomic var request_endpoint: AnyEndpoint?
    @Atomic var request_completion: Any?
    @Atomic var request_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []

    /// The last endpoint `recoveryRequest` function was called with.
    @Atomic var recoveryRequest_endpoint: AnyEndpoint?
    @Atomic var recoveryRequest_completion: Any?
    @Atomic var recoveryRequest_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []

    /// The last endpoint `uploadFile` function was called with.
    @Atomic var uploadFile_attachment: AnyChatMessageAttachment?
    @Atomic var uploadFile_progress: ((Double) -> Void)?
    @Atomic var uploadFile_completion: ((Result<URL, Error>) -> Void)?
    
    @Atomic var init_tokenRefresher: RefreshTokenBlock
    @Atomic var init_sessionConfiguration: URLSessionConfiguration
    @Atomic var init_requestEncoder: RequestEncoder
    @Atomic var init_requestDecoder: RequestDecoder
    @Atomic var init_CDNClient: CDNClient
    @Atomic var request_expectation: XCTestExpectation

    // Cleans up all recorded values
    func cleanUp() {
        executeRequest_endpoint = nil
        executeRequest_completion = nil
        executeRequest_allRecordedCalls = []
        
        request_allRecordedCalls = []
        request_endpoint = nil
        request_completion = nil
        request_expectation = .init()

        recoveryRequest_endpoint = nil
        recoveryRequest_allRecordedCalls = []
        recoveryRequest_completion = nil

        uploadFile_attachment = nil
        uploadFile_progress = nil
        uploadFile_completion = nil

        flushRequestsQueue()
    }

    override init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        requestDecoder: RequestDecoder,
        CDNClient: CDNClient,
        tokenRefresher: @escaping RefreshTokenBlock,
        queueOfflineRequest: @escaping QueueOfflineRequestBlock
    ) {
        init_tokenRefresher = tokenRefresher
        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_requestDecoder = requestDecoder
        init_CDNClient = CDNClient
        request_expectation = .init()

        super.init(
            sessionConfiguration: sessionConfiguration,
            requestEncoder: requestEncoder,
            requestDecoder: requestDecoder,
            CDNClient: CDNClient,
            tokenRefresher: tokenRefresher,
            queueOfflineRequest: queueOfflineRequest
        )
    }
    
    /// Simulates the response of the last `request` method call
    func test_simulateResponse<Response: Decodable>(_ response: Result<Response, Error>) {
        let completion = request_completion as? ((Result<Response, Error>) -> Void)
        completion?(response)
    }

    func test_simulateRecoveryResponse<Response: Decodable>(_ response: Result<Response, Error>) {
        let completion = recoveryRequest_completion as? ((Result<Response, Error>) -> Void)
        completion?(response)
    }
    
    override func request<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response: Decodable {
        request_endpoint = AnyEndpoint(endpoint)
        request_completion = completion
        _request_allRecordedCalls.mutate { $0.append((request_endpoint!, request_completion!)) }
        request_expectation.fulfill()
    }
    
    override func executeRequest<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response : Decodable {
        executeRequest_endpoint = AnyEndpoint(endpoint)
        executeRequest_completion = completion
        _executeRequest_allRecordedCalls.mutate { $0.append((executeRequest_endpoint!, executeRequest_completion!)) }
    }

    override func recoveryRequest<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response: Decodable {
        recoveryRequest_endpoint = AnyEndpoint(endpoint)
        recoveryRequest_completion = completion
        _recoveryRequest_allRecordedCalls.mutate { $0.append((recoveryRequest_endpoint!, recoveryRequest_completion!)) }
    }
    
    override func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        uploadFile_attachment = attachment
        uploadFile_progress = progress
        uploadFile_completion = completion
    }

    override func flushRequestsQueue() {
        record()
    }

    @discardableResult
    func waitForRequest(timeout: Double = 0.5) -> AnyEndpoint? {
        XCTWaiter().wait(for: [request_expectation], timeout: timeout)
        return request_endpoint
    }

    override func enterRecoveryMode() {
        record()
        super.enterRecoveryMode()
    }

    override func exitRecoveryMode() {
        record()
        super.exitRecoveryMode()
    }
}

extension APIClient_Spy {
    convenience init() {
        self.init(
            sessionConfiguration: .ephemeral,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            requestDecoder: DefaultRequestDecoder(),
            CDNClient: CDNClient_Spy(),
            tokenRefresher: { _, _ in },
            queueOfflineRequest: { _ in }
        )
    }
}
