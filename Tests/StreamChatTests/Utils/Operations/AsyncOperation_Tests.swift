//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AsyncOperation_Tests: XCTestCase {
    func testOperationCallsCompletion() {
        let expectation = expectation(description: "operation concludes")

        let operation = AsyncOperation { _, completion in
            completion(.continue)
            expectation.fulfill()
        }

        operation.start()

        waitForExpectations(timeout: 0.1) { error in
            if error != nil {
                XCTFail(error.debugDescription)
            }
        }
    }

    func testOperationDoesNotRetryIfValueIsNotPassed() {
        var operationBlockCalls = 0
        let operation = AsyncOperation { _, completion in
            operationBlockCalls += 1
            completion(.retry)
        }

        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 1)
    }

    func testOperationRetriesUpTillMaximumRetries() {
        var operationBlockCalls = 0
        let operation = AsyncOperation(maxRetries: 2) { _, completion in
            operationBlockCalls += 1
            completion(.retry)
        }

        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 3)
    }

    func testOperationRetriesUpTillSuccess() {
        var operationBlockCalls = 0
        let operation = AsyncOperation(maxRetries: 10) { _, completion in
            operationBlockCalls += 1
            if operationBlockCalls == 2 {
                completion(.continue)
            } else {
                completion(.retry)
            }
        }

        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 2)
    }

    func testOperationResetingRetriesShouldNotAccountPreviousRetries() {
        var operationBlockCalls = 0
        let operation = AsyncOperation(maxRetries: 10) { operation, completion in
            operationBlockCalls += 1
            if operationBlockCalls < 3 {
                operation.resetRetries()
            }
            completion(.retry)
        }

        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 12)
    }

    func testOperationDoesNotRetryIfCancelled() {
        var operationBlockCalls = 0
        let operation = AsyncOperation(maxRetries: 10) { _, completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                operationBlockCalls += 1
                completion(.retry)
            }
        }

        let expectation = expectation(description: "operation concludes")
        let token = operation.observe(\.isFinished) { _, change in
            guard !change.isPrior else { return }
            expectation.fulfill()
        }

        operation.start()
        // Should let it start one execution, and stop prior to the next retry
        operation.cancel()

        waitForExpectations(timeout: 10) { error in
            if let error = error {
                print(error)
                XCTFail(error.localizedDescription)
            }
        }
        token.invalidate()

        XCTAssertEqual(operationBlockCalls, 1)
    }

    func testOperationShouldNotStartIfCancelled() {
        var operationBlockCalls = 0
        let operation = AsyncOperation(maxRetries: 10) { _, completion in
            operationBlockCalls += 1
            completion(.retry)
        }

        operation.cancel()
        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 0)
    }
}

// MARK: Test Helpers

extension AsyncOperation_Tests {
    private func waitForOperationToFinish(_ operation: AsyncOperation) {
        let expectation = expectation(description: "operation concludes")
        let token = operation.observe(\.isFinished) { _, change in
            guard !change.isPrior else { return }
            expectation.fulfill()
        }

        operation.start()

        waitForExpectations(timeout: 10) { error in
            if let error = error {
                print(error)
                XCTFail(error.localizedDescription)
            }
        }
        token.invalidate()
    }
}
