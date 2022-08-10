//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
            statusCode: .unique,
            details: []
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
            statusCode: .unique,
            details: []
        )
        
        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(error.isInvalidTokenError)
        
        // Create client error wrapping the error
        let clientError = ClientError(with: error)
        
        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(clientError.isInvalidTokenError)
    }
    
    func test_isBouncedMessageError_whenUnderlayingErrorIsAccurate_returnsTrue() {
        let error = ErrorPayload(
            code: 73,
            message: .unique,
            statusCode: .unique,
            details: []
        )
        
        // Assert `isBouncedMessageError` returns true
        XCTAssertTrue(error.isBouncedMessageError)
    }
    
    func test_isBouncedMessageError_whenUnderlayingErrorIsNotAccurate_returnsFalse() {
        let error = ErrorPayload(
            code: 72,
            message: .unique,
            statusCode: .unique,
            details: []
        )
        
        // Assert `isBouncedMessageError` returns false
        XCTAssertFalse(error.isBouncedMessageError)
    }
}
