//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class RequestEncoder_Spy: RequestEncoder, Spy {
    let spyState = SpyState()
    let init_baseURL: URL
    let init_apiKey: APIKey

    weak var connectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate?

    @Atomic var encodeRequest: Result<URLRequest, Error>? = .success(URLRequest(url: .unique()))
    @Atomic var onEncodeRequestCall: (() -> Void)?
    @Atomic var encodeRequest_endpoints: [AnyEndpoint] = []
    @Atomic var encodeRequest_completion: ((Result<URLRequest, Error>) -> Void)?

    func encodeRequest<ResponsePayload>(
        for endpoint: Endpoint<ResponsePayload>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) where ResponsePayload: Decodable {
        record()
        encodeRequest_endpoints.append(AnyEndpoint(endpoint))
        encodeRequest_completion = completion

        if let result = encodeRequest {
            completion(result)
        }
        onEncodeRequestCall?()
    }

    required init(baseURL: URL, apiKey: APIKey) {
        init_baseURL = baseURL
        init_apiKey = apiKey
    }
}
