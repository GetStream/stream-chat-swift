//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ClientError_Tests: XCTestCase {
    func test_isInvalidTokenError_whenUnderlayingErrorIsInvalidToken_returnsTrue() {
        // Create error code withing `ErrorPayload.tokenInvalidErrorCodes` range
        let error = ErrorPayload(
            code: .random(in: ClosedRange.tokenInvalidErrorCodes),
            message: .unique,
            statusCode: .unique
        )

        // Assert `isInvalidTokenError` returns true
        XCTAssertTrue(error.isInvalidTokenError)

        // Create client error wrapping the error
        let clientError = ClientError(with: error)

        // Assert `isInvalidTokenError` returns true
        XCTAssertTrue(clientError.isInvalidTokenError)
    }

    func test_isInvalidTokenError_whenUnderlayingErrorIsNotInvalidToken_returnsFalse() {
        // Create error code outside `ErrorPayload.tokenInvalidErrorCodes` range
        let error = ErrorPayload(
            code: ClosedRange.tokenInvalidErrorCodes.lowerBound - 1,
            message: .unique,
            statusCode: .unique
        )

        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(error.isInvalidTokenError)

        // Create client error wrapping the error
        let clientError = ClientError(with: error)

        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(clientError.isInvalidTokenError)
    }

    func test_rateLimitError_isEphemeralError() {
        let errorPayload = ErrorPayload(
            code: 9,
            message: .unique,
            statusCode: 429
        )

        let error = ClientError(with: errorPayload)

        // Assert `isRateLimitError` returns true
        XCTAssertTrue(error.isRateLimitError)
        XCTAssertTrue(ClientError.isEphemeral(error: error))
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
