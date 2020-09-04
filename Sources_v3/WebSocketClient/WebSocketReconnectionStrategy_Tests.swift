//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class DefaultReconnectionStrategy_Tests: XCTestCase {
    var strategy: DefaultReconnectionStrategy!
    
    override func setUp() {
        super.setUp()
        strategy = DefaultReconnectionStrategy()
    }
    
    func test_delaysAreIncreasing() throws {
        // Ask for reconection delay 10 times
        var delays: [TimeInterval] = []
        for _ in 0..<10 {
            let delay = try XCTUnwrap(strategy.reconnectionDelay(forConnectionError: nil))
            delays.append(delay)
        }
        
        // Check the delays are increasing
        XCTAssert(delays.first! < delays.last!)
    }
    
    func test_delaysResetWhenConnectionSucceeds() throws {
        // Ask for reconection delay 10 times
        var delays: [TimeInterval] = []
        for _ in 0..<10 {
            let delay = strategy.reconnectionDelay(forConnectionError: nil)
            XCTAssertNotNil(delay)
            delays.append(delay!)
        }
        
        strategy.sucessfullyConnected()
        
        // Ask for a new delay after a successful connection and check it's small again
        let newDelay = try XCTUnwrap(strategy.reconnectionDelay(forConnectionError: nil))
        XCTAssert(newDelay < delays.last!)
    }
    
    func test_returnsNilForStopError() {
        let stopError = WebSocketEngineError(
            reason: "Testing stop error",
            code: WebSocketEngineError.stopErrorCode,
            engineError: nil
        )
        
        let delay = strategy.reconnectionDelay(forConnectionError: stopError)
        XCTAssertNil(delay)
    }
    
    func test_returnsNilForInvalidTokenErrors() {
        let invalidTokenErrorCodes = [40, 41, 42, 43]
        invalidTokenErrorCodes.forEach { invalidTokenErrorCode in
            let error = ErrorPayload(code: invalidTokenErrorCode, message: "", statusCode: 0)
            let delay = strategy.reconnectionDelay(forConnectionError: error)
            XCTAssertNil(delay)
        }
        
        // Check other error codes return a non-nil delay
        let error = ErrorPayload(code: 66, message: "", statusCode: 0)
        let delay = strategy.reconnectionDelay(forConnectionError: error)
        XCTAssertNotNil(delay)
    }
    
    func test_returnsNilForInternetIsOfflineError() {
        let error = WebSocketEngineError(
            error:
            NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: nil
            )
        )
        let delay = strategy.reconnectionDelay(forConnectionError: error)
        XCTAssertNil(delay)
    }
}
