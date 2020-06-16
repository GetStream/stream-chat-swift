//
// WebSocketReconnectionStrategy_tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

final class DefaultReconnectionStrategyTests: XCTestCase {
  var strategy: DefaultReconnectionStrategy!

  override func setUp() {
    super.setUp()
    strategy = DefaultReconnectionStrategy()
  }

  func test_delaysAreIncreasing() throws {
    // Ask for reconection delay 10 times
    var delays: [TimeInterval] = []
    for _ in 0 ..< 10 {
      let delay = try XCTUnwrap(strategy.reconnectionDelay(forConnectionError: nil))
      delays.append(delay)
    }

    // Check the delays are increasing
    XCTAssert(delays.first! < delays.last!)
  }

  func test_delaysResetWhenConnectionSucceeds() throws {
    // Ask for reconection delay 10 times
    var delays: [TimeInterval] = []
    for _ in 0 ..< 10 {
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
      let error = ServerResponseError(code: invalidTokenErrorCode, message: "", statusCode: 0)
      let delay = strategy.reconnectionDelay(forConnectionError: error)
      XCTAssertNil(delay)
    }

    // Check other error codes return a non-nil delay
    let error = ServerResponseError(code: 66, message: "", statusCode: 0)
    let delay = strategy.reconnectionDelay(forConnectionError: error)
    XCTAssertNotNil(delay)
  }
}
