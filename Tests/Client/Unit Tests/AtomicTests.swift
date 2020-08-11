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
        AssertAsync {
            Assert.willBeEqual(callbackNewValue, newValue)
            Assert.willBeEqual(callbackOldValue, initialValue)
        }
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

    func test_Atomic_keyPathHelpersWithOptionalElement() {
        // Setup
        struct Helper: Equatable {
            var elements: [Int]? = []
        }
        let atomicValue: Atomic<Helper> = Atomic(Helper())

        // Actions
        atomicValue.update(\.elements, to: [0])
        XCTAssertEqual(atomicValue.get(), Helper(elements: [0]))

        atomicValue.elements = [1]
        XCTAssertEqual(atomicValue.get(), Helper(elements: [1]))

        atomicValue.elements = nil
        XCTAssertEqual(atomicValue.get(), Helper(elements: nil))
    }
    
    func test_Atomic_dictionaryHelpers() {
        let atomicValue = Atomic(["Luke": 1])
        XCTAssertEqual(atomicValue["Luke"], 1)
    }

    func test_Atomic_whenCalledRecursively() {
        // Setup
        let atomicValue = Atomic("Luke")

        // Action
        atomicValue.update { (oldValue) -> String in
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
    
    func test_Atomic_withOptionalType() {
        let atomicValue: Atomic<String?> = Atomic(nil)
        XCTAssertEqual(atomicValue.get(), nil)
        
        atomicValue.set("Luke")
        XCTAssertEqual(atomicValue.get(), "Luke")
        
        atomicValue.update { (current) -> String? in
            XCTAssertEqual(atomicValue.get(), "Luke")
            return nil
        }
        XCTAssertEqual(atomicValue.get(), nil)
    }
}

// MARK: - Stress tests

extension AtomicTests {

    /// Increase `numberOfStressTestCycles` significantly to properly stress-test `Atomic`.
    var numberOfStressTestCycles: Int { 50 }

    func test_Atomic_underHeavyLoad() {
        for _ in 0..<100 {
            test_Atomic_usedAsCounter()
            test_Atomic_usedWithCollection()
            test_Atomic_whenSetAndGetCalledSimultaneously()
            test_Atomic_whenCalledFromMainThred()
        }
    }

    func test_Atomic_usedAsCounter() {
        var atomicValue: Atomic<Int>! = .init(0)

        // Count up to numberOfCycles
        for _ in 0..<numberOfStressTestCycles {
            DispatchQueue.random.async {
                atomicValue += 1
            }
        }
        AssertAsync.willBeEqual(atomicValue.get(), self.numberOfStressTestCycles)

        // Count down to zero
        for _ in 0..<numberOfStressTestCycles {
            DispatchQueue.random.async {
                atomicValue -= 1
            }
        }
        AssertAsync.willBeEqual(atomicValue.get(), 0)

        // Check for memory leaks
        weak var weakValue = atomicValue
        atomicValue = nil

        AssertAsync.willBeNil(weakValue)
    }

    func test_Atomic_usedWithCollection() {
        var atomicValue: Atomic<[String: Int]>! = .init([:])

        for idx in 0..<numberOfStressTestCycles {
            DispatchQueue.random.async {
                atomicValue.update {
                    var mutable = $0
                    mutable["\(idx)"] = idx
                    return mutable
                }
            }
        }

        AssertAsync.willBeEqual(atomicValue.get().count, self.numberOfStressTestCycles)

        // Check for memory leaks
        weak var weakValue = atomicValue
        atomicValue = nil

        AssertAsync.willBeNil(weakValue)
    }

    func test_Atomic_whenSetAndGetCalledSimultaneously() {
        var atomicValue: Atomic<[String: Int]>! = .init([:])

        for idx in 0..<numberOfStressTestCycles {

            DispatchQueue.random.async {
                atomicValue.update {
                    var mutable = $0
                    mutable["\(idx)"] = idx
                    return mutable
                }
            }

            for _ in 0...5 {
                // We need to capture the value explicitly. Without this the tests randomly crashes after
                // `atomicValue` is assigned to `nil`.
                DispatchQueue.random.async { [atomicValue] in
                    _ = atomicValue?.get()
                }
            }
        }

        AssertAsync.willBeEqual(atomicValue.get().count, self.numberOfStressTestCycles)

        // Check for memory leaks
        weak var weakValue = atomicValue
        atomicValue = nil

        AssertAsync.willBeNil(weakValue)
    }

    func test_Atomic_whenCalledFromMainThred() {
        var value: Atomic<[String: Int]>! = .init([:])

        for idx in 0..<numberOfStressTestCycles {
            value.update {
                var mutable = $0
                mutable["\(idx)"] = idx
                return mutable
            }

            value.set(["random": 2020])

            _ = value.get()
        }

        XCTAssertEqual(value.get(), ["random": 2020])

        // Check for memory leaks
        weak var weakValue = value
        value = nil

        AssertAsync.willBeNil(weakValue)
    }
}

private extension DispatchQueue {

    private static let queueIdKey = DispatchSpecificKey<String>()
    private static let testQueueId = UUID().uuidString

    /// Returns one of the existing global Dispatch queues.
    static var random: DispatchQueue {
        let allQoS: [DispatchQoS.QoSClass] = [
            .userInteractive,
            .userInitiated,
            .default
        ]
        return DispatchQueue.global(qos: allQoS.randomElement()!)
    }

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
