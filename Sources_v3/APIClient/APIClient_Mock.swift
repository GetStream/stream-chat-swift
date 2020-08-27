//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

/// Mock implementation of APIClient allowing easy control and simulation of responses.
class APIClientMock: APIClient {
    @Atomic var request_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []
    
    /// The last endpoint `request` function was called with.
    @Atomic var request_endpoint: AnyEndpoint?
    @Atomic var request_completion: Any?
    
    @Atomic var init_sessionConfiguration: URLSessionConfiguration
    @Atomic var init_requestEncoder: RequestEncoder
    @Atomic var init_requestDecoder: RequestDecoder

    // Cleans up all recorded values
    func cleanUp() {
        request_allRecordedCalls = []
        request_endpoint = nil
        request_completion = nil
    }
    
    override init(sessionConfiguration: URLSessionConfiguration, requestEncoder: RequestEncoder, requestDecoder: RequestDecoder) {
        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_requestDecoder = requestDecoder
        
        super.init(sessionConfiguration: sessionConfiguration, requestEncoder: requestEncoder, requestDecoder: requestDecoder)
    }
    
    /// Simulates the response of the last `request` method call
    func test_simulateResponse<Response: Decodable>(_ response: Result<Response, Error>) {
        let completion = request_completion as! ((Result<Response, Error>) -> Void)
        completion(response)
    }
    
    override func request<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response: Decodable {
        request_endpoint = AnyEndpoint(endpoint)
        request_completion = completion
        request_allRecordedCalls.append((request_endpoint!, request_completion!))
    }
}

extension APIClientMock {
    convenience init() {
        self.init(
            sessionConfiguration: .default,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            requestDecoder: DefaultRequestDecoder()
        )
    }
}
