//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

private enum Config {
    static let executorTitle = "BlockingExecutorTests"
    static let expectationTimeout: TimeInterval = 5
}

class BlockingExecutor_Tests: XCTestCase {
    private var executor: BlockingExecutor!

    override func setUp() {
        executor = BlockingExecutor(executorTitle: Config.executorTitle)
        super.setUp()
    }

    override func tearDown() {
        executor = nil
        super.tearDown()
    }


    func testNoErrorWhenExecuteAfterFinishedOperation() {
        var ticks = 0
        let expected = expectation(description: "Executor completion called")
        let operationBlock: BlockingExecutor.ExecutorClosure = { executorCompletion in
            ticks += 1
            executorCompletion(nil)
        }

        // Given
        // One operation finished
        executor.executeBlocking(
            executor: operationBlock,
            completion: { [weak self] error in

                XCTAssertNil(error)

                // When
                // Execute second operation
                self?.executor.executeBlocking(
                    executor: operationBlock,
                    completion: { error in
                        // Then
                        // No error
                        XCTAssertNil(error)

                        // Then
                        // Ticks == 2
                        XCTAssertEqual(ticks, 2)

                        expected.fulfill()
                    }
                )
            }
        )

        wait(for: [expected], timeout: Config.expectationTimeout)
    }

    func testBackgroundOperationCorrectlyCompleted() {
        var ticks = 0
        let expected = expectation(description: "Executor completion called")

        let operationBlock: BlockingExecutor.ExecutorClosure = { executorCompletion in
            DispatchQueue.global().async {
                ticks += 1

                // Completion should be called inside the background
                executorCompletion(nil)
            }
        }

        // Given
        // One operation finished
        executor.executeBlocking(
            executor: operationBlock,
            completion: { error in
                XCTAssertNil(error)
                expected.fulfill()
            }
        )

        wait(for: [expected], timeout: Config.expectationTimeout)
    }

    func testSameErrorIsPassedFromExecutorBlock() {
        let error = NSError(domain: "tests", code: 123)

        executor.executeBlocking(
            executor: { executorCompletion in
                executorCompletion(error)
            },
            completion: { completionError in
                XCTAssertNotNil(completionError)
                XCTAssertEqual(completionError as! NSError, error)
            }
        )
    }

    func testExecuteOnOperationInProgressReturnsError() {
        // Given
        // One operations is in progress
        executor.executeBlocking(
            executor: { _ in },
            completion: { completionError in
                XCTAssert(false, "Should never be called in this test")
            }
        )

        // When
        // Trying to execute second operation
        executor.executeBlocking(
            executor: { _ in },
            completion: { completionError in
                XCTAssertNotNil(completionError)

                // Then
                // Got error already in progress
                XCTAssert(completionError is ClientError.ExecutingAlreadyInProgress)

                // Check label is correct
                let error = completionError as! ClientError.ExecutingAlreadyInProgress
                XCTAssertEqual(error.executorTitle, Config.executorTitle)
            }
        )
    }
    
    func testTwoExecutorsWorkingCorrectly() {
        // Given
        // Two executors with different labels
        let firstLabel = "BlockingExecutorTests_First"
        let secondLabel = "BlockingExecutorTests_Two"

        let firstExecutor = BlockingExecutor(executorTitle: firstLabel)
        let secondExecutor = BlockingExecutor(executorTitle: secondLabel)

        firstExecutor.executeBlocking(
            executor: { _ in },
            completion: { completionError in
                XCTAssert(false, "Should never be called in this test")
                XCTAssertNil(completionError)
            }
        )

        secondExecutor.executeBlocking(
            executor: { _ in },
            completion: { completionError in
                XCTAssert(false, "Should never be called in this test")
                XCTAssertNil(completionError)
            }
        )
    }
}
