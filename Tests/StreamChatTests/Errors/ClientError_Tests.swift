//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamCore
import XCTest

final class ClientError_Tests: XCTestCase {
    func test_rateLimitError_isNotEphemeralError() {
        let errorPayload = ErrorPayload(
            code: 9,
            message: .unique,
            statusCode: 429
        )

        let error = ClientError(with: errorPayload)

        XCTAssertTrue(error.isRateLimitError)
        XCTAssertFalse(ClientError.isEphemeral(error: error))
    }

    func test_temporaryErrors_areEphemeralError() {
        [
            NSURLErrorCancelled,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorBadServerResponse,
            NSURLErrorUserCancelledAuthentication,
            NSURLErrorCannotLoadFromNetwork,
            NSURLErrorDataNotAllowed
        ].forEach {
            let error = NSError(domain: NSURLErrorDomain, code: $0)
            XCTAssertTrue(ClientError.isEphemeral(error: error))
        }
    }

    func test_otherNSURLErrors_areNotEphemeralError() {
        [
            NSURLErrorUnknown,
            NSURLErrorUnsupportedURL,
            NSURLErrorCannotParseResponse
        ].forEach {
            let error = NSError(domain: NSURLErrorDomain, code: $0)
            XCTAssertFalse(ClientError.isEphemeral(error: error))
        }
    }
}
