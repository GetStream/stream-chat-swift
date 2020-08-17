//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

/// Mock implementation of APIClient allowing easy control and simulation of responses.
class APIClientMock: APIClient {
    /// The last endpoint `request` function was called with.
    var request_endpoint: AnyEndpoint?
    var request_completion: Any?
    
    var init_sessionConfiguration: URLSessionConfiguration
    var init_requestEncoder: RequestEncoder
    var init_requestDecoder: RequestDecoder
    
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
    }
}

extension APIClientMock {
    convenience init() {
        self.init(sessionConfiguration: .default,
                  requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
                  requestDecoder: DefaultRequestDecoder())
    }
}
