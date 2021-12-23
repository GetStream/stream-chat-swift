//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

/// Mock implementation of APIClient allowing easy control and simulation of responses.
class APIClientMock: APIClient {
    @Atomic var request_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []
    
    /// The last endpoint `request` function was called with.
    @Atomic var request_endpoint: AnyEndpoint?
    @Atomic var request_completion: Any?

    /// The last endpoint `uploadFile` function was called with.
    @Atomic var uploadFile_attachment: AnyChatMessageAttachment?
    @Atomic var uploadFile_progress: ((Double) -> Void)?
    @Atomic var uploadFile_completion: ((Result<URL, Error>) -> Void)?
    
    /// The last params `flushRequestsQueue` function was called with.
    @Atomic var flushRequestsQueue_timeout: TimeInterval?
    @Atomic var flushRequestsQueue_itemAction: ((APIClient.RequestsQueueItem) -> Void)?
    
    @Atomic var init_sessionConfiguration: URLSessionConfiguration
    @Atomic var init_requestEncoder: RequestEncoder
    @Atomic var init_requestDecoder: RequestDecoder
    @Atomic var init_CDNClient: CDNClient
    @Atomic var request_expectation: XCTestExpectation

    // Cleans up all recorded values
    func cleanUp() {
        request_allRecordedCalls = []
        request_endpoint = nil
        request_completion = nil
        request_expectation = .init()

        uploadFile_attachment = nil
        uploadFile_progress = nil
        uploadFile_completion = nil
        
        flushRequestsQueue_timeout = nil
        flushRequestsQueue_itemAction = nil
    }
    
    override init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        requestDecoder: RequestDecoder,
        CDNClient: CDNClient,
        tokenRefresher: ((@escaping () -> Void) -> Void)!
    ) {
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
            tokenRefresher: tokenRefresher
        )
    }
    
    /// Simulates the response of the last `request` method call
    func test_simulateResponse<Response: Decodable>(_ response: Result<Response, Error>) {
        let completion = request_completion as! ((Result<Response, Error>) -> Void)
        completion(response)
    }
    
    override func request<Response>(
        endpoint: Endpoint<Response>,
        timeout: TimeInterval,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response: Decodable {
        request_endpoint = AnyEndpoint(endpoint)
        request_completion = completion
        _request_allRecordedCalls.mutate { $0.append((request_endpoint!, request_completion!)) }
        request_expectation.fulfill()
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
    
    override func flushRequestsQueue(
        after timeout: TimeInterval = 0,
        itemAction: ((APIClient.RequestsQueueItem) -> Void)? = nil
    ) {
        flushRequestsQueue_timeout = timeout
        flushRequestsQueue_itemAction = itemAction
    }

    @discardableResult
    func waitForRequest(timeout: Double = 0.5) -> AnyEndpoint? {
        XCTWaiter().wait(for: [request_expectation], timeout: timeout)
        return request_endpoint
    }
}

extension APIClientMock {
    convenience init() {
        self.init(
            sessionConfiguration: .ephemeral,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            requestDecoder: DefaultRequestDecoder(),
            CDNClient: CDNClient_Mock(),
            tokenRefresher: { _ in }
        )
    }
}
