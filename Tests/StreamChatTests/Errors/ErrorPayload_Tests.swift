//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ErrorPayload_Tests: XCTestCase {
    // MARK: - Invalid token
    
    func test_isInvalidTokenError_whenCodeIsInsideInvalidTokenRange_returnsTrue() {
        // Iterate invalid token codes range
        for code in ClosedRange.tokenInvalidErrorCodes {
            // Create the error with invalid token code
            let error = ErrorPayload(
                code: code,
                message: .unique,
                statusCode: .unique,
                details: []
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
                statusCode: .unique,
                details: []
            )
            
            // Assert `isInvalidTokenError` returns false
            XCTAssertFalse(error.isInvalidTokenError)
        }
    }
    
    // MARK: - Client error
    
    func test_isClientError_whenCodeIsInsideClientErrorRange_returnsTrue() {
        // Iterate invalid token codes range
        for code in ClosedRange.clientErrorCodes {
            // Create the error with client error status code
            let error = ErrorPayload(
                code: .unique,
                message: .unique,
                statusCode: code,
                details: []
            )
            
            // Assert `isClientError` returns true
            XCTAssertTrue(error.isClientError)
        }
    }
    
    func test_isClientError_whenCodeIsOutsideClientErrorRange_returnsFalse() {
        // Create array of error codes outside client error range
        let codesOutsideClientErrorRange = [
            ClosedRange.clientErrorCodes.lowerBound - 1,
            ClosedRange.clientErrorCodes.upperBound + 1
        ]
        
        // Iterate error codes
        for code in codesOutsideClientErrorRange {
            // Create the error with code outside invalid token range
            let error = ErrorPayload(
                code: .unique,
                message: .unique,
                statusCode: code,
                details: []
            )
            
            // Assert `isClientError` returns false
            XCTAssertFalse(error.isClientError)
        }
    }
}
