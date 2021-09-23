//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

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
    
    @Atomic var init_sessionConfiguration: URLSessionConfiguration
    @Atomic var init_requestEncoder: RequestEncoder
    @Atomic var init_requestDecoder: RequestDecoder
    @Atomic var init_CDNClient: CDNClient

    // Cleans up all recorded values
    func cleanUp() {
        request_allRecordedCalls = []
        request_endpoint = nil
        request_completion = nil
    }
    
    override init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        requestDecoder: RequestDecoder,
        CDNClient: CDNClient,
        tokenRefresher: ((ClientError, @escaping () -> Void) -> Void)!
    ) {
        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_requestDecoder = requestDecoder
        init_CDNClient = CDNClient
        
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
}

extension APIClientMock {
    convenience init() {
        self.init(
            sessionConfiguration: .ephemeral,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            requestDecoder: DefaultRequestDecoder(),
            CDNClient: CDNClient_Mock(),
            tokenRefresher: { _, _ in }
        )
    }
}
