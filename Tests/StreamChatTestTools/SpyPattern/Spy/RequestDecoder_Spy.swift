//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class RequestDecoder_Spy: RequestDecoder, Spy {
    var recordedFunctions: [String] = []
    var decodeRequestResponse: Result<Any, Error>?
    var decodeRequestDelay: TimeInterval?

    var decodeRequestResponse_data: Data?
    var decodeRequestResponse_response: HTTPURLResponse?
    var decodeRequestResponse_error: Error?

    func decodeRequestResponse<ResponseType>(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) throws -> ResponseType where ResponseType: Decodable {
        record()
        decodeRequestResponse_data = data
        decodeRequestResponse_response = response as? HTTPURLResponse
        decodeRequestResponse_error = error

        guard let simulatedResponse = decodeRequestResponse else {
            log.warning("RequestDecoder_Spy simulated response not set. Throwing a TestError.")
            throw TestError()
        }

        if let decodeRequestDelay = decodeRequestDelay {
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.asyncAfter(deadline: .now() + decodeRequestDelay) { group.leave() }
            group.wait()
        }
        switch simulatedResponse {
        case let .success(response):
            return response as! ResponseType
        case let .failure(error):
            throw error
        }
    }
}
