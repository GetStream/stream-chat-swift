//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ErrorPayload_Tests: XCTestCase {
    func test_isInvalidTokenError_whenCodeIsInsideInvalidTokenRange_returnsTrue() {
        // Iterate invalid token codes range
        for code in ClosedRange.tokenInvalidErrorCodes {
            // Create the error with invalid token code
            let error = ErrorPayload(
                code: code,
                message: .unique,
                statusCode: .unique
            )
            
            // Assert `isInvalidTokenError` returns true
            XCTAssertTrue(error.isInvalidTokenError)
        }
    }
    
    func test_isInvalidTokenError_whenCodeIsOutsideInvalidTokenRange_returnsFalse() {
        // Create array of error codes outside invalid token range
        let codesOutsideInvalidTokenRange = [
            ClosedRange.tokenInvalidErrorCodes.lowerBound - 1,
            ClosedRange.tokenInvalidErrorCodes.upperBound + 1
        ]
        
        // Iterate error codes
        for code in codesOutsideInvalidTokenRange {
            // Create the error with code outside invalid token range
            let error = ErrorPayload(
                code: code,
                message: .unique,
                statusCode: .unique
            )
            
            // Assert `isInvalidTokenError` returns false
            XCTAssertFalse(error.isInvalidTokenError)
        }
    }
}
