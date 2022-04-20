//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class RequestEncoder_Spy: RequestEncoder, Spy {
    var recordedFunctions: [String] = []
    let init_baseURL: URL
    let init_apiKey: APIKey

    weak var connectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate?

    var encodeRequest: Result<URLRequest, Error>? = .success(URLRequest(url: .unique()))
    var encodeRequest_endpoints: [AnyEndpoint] = []
    var encodeRequest_completion: ((Result<URLRequest, Error>) -> Void)?

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
    }

    required init(baseURL: URL, apiKey: APIKey) {
        init_baseURL = baseURL
        init_apiKey = apiKey
    }
}
