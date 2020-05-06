//
//  AtomicTests.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class AtomicTests: XCTestCase {

    func test_Atomic_whenValueChanged_callsDidSetCallback() {
        // Setup
        let initialValue = "Anakin"
        let newValue = "Vader"

        var callbackNewValue: String?
        var callbackOldValue: String?

        let atomicValue = Atomic(initialValue, callbackQueue: .testQueue) {
            XCTAssertTrue(DispatchQueue.isTestQueue, "Callback called on an incorrect queue.")
            callbackNewValue = $0
            callbackOldValue = $1
        }
        assert(atomicValue.get() == initialValue)

        // Action
        atomicValue.set(newValue)

        // Assert
        AssertEqualEventually(callbackNewValue, newValue)
        AssertEqualEventually(callbackOldValue, initialValue)
    }

    func test_Atomic_keyPathHelpers() {
        // Setup
        struct Helper: Equatable {
            var elements: [Int] = []
        }
        let atomicValue = Atomic(Helper())

        // Actions
        atomicValue.update(\.elements, to: [0])
        XCTAssertEqual(atomicValue.get(), Helper(elements: [0]))

        atomicValue.elements = [1]
        XCTAssertEqual(atomicValue.get(), Helper(elements: [1]))

        atomicValue.append(to: \.elements, 2)
        XCTAssertEqual(atomicValue.get(), Helper(elements: [1, 2]))
    }

    func test_Atomic_dictionaryHelpers() {
        let atomicValue = Atomic(["Luke": 1])
        XCTAssertEqual(atomicValue["Luke"], 1)
    }

    func test_Atomic_whenCalledRecursively() {
        // Setup
        let atomicValue = Atomic("Luke")

        // Action
        atomicValue.update { (oldValue) -> String? in
            // The current value should be same as `oldValue`
            XCTAssertEqual(atomicValue.get(), oldValue)

            atomicValue.set("Skywalker")
            // The current value should be updated
            XCTAssertEqual(atomicValue.get(), "Skywalker")

            atomicValue.update { oldValue in
                // The current value should be same as `oldValue`
                XCTAssertEqual(atomicValue.get(), oldValue)
                return "Vader!"
            }
            // The current value should be updated
            XCTAssertEqual(atomicValue.get(), "Vader!")

            // Finally, the return value from `update` closure should override previous changes
            return "Leia"
        }

        XCTAssertEqual(atomicValue.get(), "Leia")
    }
}

private extension DispatchQueue {

    private static let queueIdKey = DispatchSpecificKey<String>()
    private static let testQueueId = UUID().uuidString

    /// Creates a queue which can be later identified.
    static var testQueue: DispatchQueue {
        let queue = DispatchQueue(label: "Test queue")
        queue.setSpecific(key: Self.queueIdKey, value: testQueueId)
        return queue
    }

    /// Checks if the current queue is the queue created by `DispatchQueue.testQueue`.
    static var isTestQueue: Bool {
        DispatchQueue.getSpecific(key: queueIdKey) == testQueueId
    }
}
