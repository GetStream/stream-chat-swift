//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AsyncOperation_Tests: XCTestCase {
    func test_operationCallsCompletion_whenFinished() {
        let expectation = expectation(description: "operation concludes")

        let operation = AsyncOperation { _, completion in
            completion(.continue)
            expectation.fulfill()
        }

        operation.start()

        waitForExpectations(timeout: 0.5) { error in
            if error != nil {
                XCTFail(error.debugDescription)
            }
        }
    }

    func test_operationDoesNotRetry_whenValueIsNotPassed() {
        var operationBlockCalls = 0
        let operation = AsyncOperation { _, completion in
            operationBlockCalls += 1
            completion(.retry)
        }

        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 1)
    }

    func test_operationRetriesUpTillMaximumRetries() {
        var operationBlockCalls = 0
        let operation = AsyncOperation(maxRetries: 2) { _, completion in
            operationBlockCalls += 1
            completion(.retry)
        }

        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 3)
    }

    func test_operationRetriesUpTillSuccess() {
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

    func test_operationResetingRetriesShouldNotAccountPreviousRetries() {
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

    func test_operationDoesNotRetry_whenCancelled() {
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

    func test_operationShouldNotStart_whenCancelled() {
        var operationBlockCalls = 0
        let operation = AsyncOperation(maxRetries: 10) { _, completion in
            operationBlockCalls += 1
            completion(.retry)
        }

        operation.cancel()
        waitForOperationToFinish(operation)
        XCTAssertEqual(operationBlockCalls, 0)
    }

    func test_baseOperation_isThreadSafe() {
        let operation = BaseOperation()

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            operation.isFinished = true
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = operation.isFinished
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            operation.isFinished = false
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            operation.isExecuting = true
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = operation.isExecuting
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            operation.isExecuting = false
        }
    }

    func test_operation_isThreadSafe() {
        for _ in (1...100) {
            let operation = AsyncOperation { _, done in
                DispatchQueue.global().async {
                    done(.continue)
                }
            }

            operation.start()

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                operation.isFinished = true
            }
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                _ = operation.isFinished
            }
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                operation.isFinished = false
            }
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                operation.isExecuting = true
            }
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                _ = operation.isExecuting
            }
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                operation.isExecuting = false
            }
        }
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
